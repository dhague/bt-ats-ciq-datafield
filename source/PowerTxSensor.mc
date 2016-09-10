//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as System;

class PowerTxSensor extends Ant.GenericChannel {
    const POWER_DEVICE_TYPE = 0x0B;
    const CHANNEL_PERIOD = 8182;

    hidden var chanAssign;
    var powerSensorId;
    var powerData;
    var deviceCfg;

    class PowerData {
        var eventCount;
        var eventTime;
        var cumulativePower;
        var instantaneousPower;
        var cadence;

        function initialize() {
            eventCount = 0;
            eventTime = 0;
            cumulativePower = 0;
            instantaneousPower = 0;
            cadence = 0;
        }
    }

    class PowerDataPage {
    }

    function initialize() {

        // Get the channel
        chanAssign = new Ant.ChannelAssignment(
            Ant.CHANNEL_TYPE_TX_NOT_RX,
            Ant.NETWORK_PLUS);
        GenericChannel.initialize(method(:onMessage), chanAssign);

        powerSensorId = Application.getApp().getProperty("antPowerSensorId");
        if (!powerSensorId) {
            powerSensorId = Time.now().value() & 0xfffe + 1; // Set ID to a "random" nonzero 16-bit number
            Application.getApp().setProperty("antPowerSensorId", powerSensorId);
        }
        System.println("antPowerSensorId: "+Application.getApp().getProperty("antPowerSensorId"));

        // Set the configuration
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => powerSensorId,
            :deviceType => POWER_DEVICE_TYPE,
            :transmissionType => 0,
            :messagePeriod => CHANNEL_PERIOD,
            :radioFrequency => 57,              //Ant+ Frequency
            :searchTimeoutLowPriority => 10,    //Timeout in 25s
            :searchThreshold => 0} );           //Pair to all receiving head units
        GenericChannel.setDeviceConfig(deviceCfg);

        searching = true;

        powerData = new PowerData();
        //onMessageTest(null);
    }

    function open() {
        // Open the channel
        GenericChannel.open();
        searching = true;
    }

    function closeSensor() {
        GenericChannel.close();
    }

    //(:test)
    function onMessageTest(logger) {
        // Simulate a calibration message
        var msg = new Ant.Message();
//        msg.messageId = 0x4E;
//        msg.deviceNumber = 41558;
//        msg.deviceType = 0x79;
//        msg.setPayload([0x55, 0xC6, 0x45, 0x50, 0xF4, 0x6F, 0xBB, 0x3A]);
//        onMessage(msg);
//        msg.setPayload([0x55, 0xC6, 0x45, 0x50, 0xF3, 0x71, 0xBF, 0x3A]);
//        onMessage(msg);
//        msg.setPayload([0x55, 0xC6, 0x45, 0x50, 0xF1, 0x72, 0xC1, 0x3A]);
//        onMessage(msg);
//        return revsPerSec > 0.0; // returning true indicates pass, false indicates failure
    }

    // Power was updated, so send out an ANT+ message
    function onPowerChange(power) {
        powerData.eventCount = (powerData.eventCount + 1) & 0xff;
        powerData.cumulativePower = (powerData.cumulativePower + Integer(power)) & 0xffff;
        powerData.instantaneousPower = power;
        powerData.cadence = Time.now().value() % 60;

        var msg = new Ant.Message();
        msg.messageId = 0x4E;
        msg.deviceNumber = powerSensorId;
        msg.deviceType = POWER_DEVICE_TYPE;
        payload = new [8];
        payload[0] = 0x10;  // standard power-only message
        payload[1] = powerData.eventCount;
        payload[2] = 0xFF; // Pedal power not used
        payload[3] = cadence;
        payload[4] = powerData.cumulativePower & 0xff;
        payload[5] = powerData.cumulativePower << 8;
        payload[6] = powerData.instantaneousPower & 0xff;
        payload[7] = powerData.instantaneousPower << 8;
        message.setPayload(payload);
        GenericChannel.sendBroadcast(message);
    }


    // Page 1 is calibration

    function onMessage(msg) {
        System.println("msg.messageId:"+msg.messageId);

        currentMessageTime = Time.now();
        // Parse the payload
        var payload = msg.getPayload();

        if( Ant.MSG_ID_BROADCAST_DATA == msg.messageId ) {
            // Were we searching?
            if (searching) {
                searching = false;
                // Update our device configuration primarily to see the device number of the sensor we paired to
                deviceCfg = GenericChannel.getDeviceConfig();
                System.println("deviceCfg.deviceNumber:"+deviceCfg.deviceNumber);
                System.println("deviceCfg.deviceType:"+deviceCfg.deviceType);
            }

            var dp = null;
            // Get the datapage according to the device type in the deviceCfg
            if (deviceCfg.deviceType == SPEED_DEVICE_TYPE) {
                //System.println("Speed device");
                dp = new SpeedDataPage();
            }
            else if (deviceCfg.deviceType == CADENCE_DEVICE_TYPE) {
                //System.println("Cadence device");
                dp = new CadenceDataPage();
            }
            else if (deviceCfg.deviceType == SPEED_CADENCE_DEVICE_TYPE) {
                //System.println("Speed & Cadence device");
                dp = new SpeedCadenceDataPage();
            }

            if (dp == null) {
                return;
            }
            var messageData = new SpeedCadenceData();
            //System.println("Parse message");
            dp.parse(msg.getPayload(), messageData);
            //System.println("messageData.speedEventTime: "+messageData.speedEventTime);
            //System.println("messageData.speedRevCount: "+messageData.speedRevCount);

            if (currentData == null) {
                previousData = currentData;
                currentData = messageData;
                return;
            }

            if (!stopped() && messageData.speedEventTime != currentData.speedEventTime) {
                // Calculate speed from previously-held data, if there is a change
                previousData = currentData;
                currentData = messageData;
                //System.println("Previous data: "+previousData);
                //System.println("Current data: "+currentData);
                if (previousData != null) {
                    var currentEventTime = currentData.speedEventTime;
                    if (currentEventTime < previousData.speedEventTime) {
                        currentEventTime = currentEventTime + 65536/1024;
                    }
                    var timeDiff = currentEventTime - previousData.speedEventTime;
                    var currentRevCount = currentData.speedRevCount;
                    if (currentRevCount < previousData.speedRevCount) {
                        currentRevCount = currentRevCount + 65536;
                    }
                    var revsDiff = currentRevCount - previousData.speedRevCount;
                    revsPerSec = revsDiff / timeDiff;
                    System.println("Sensor Revs/sec: "+revsPerSec);
                } else {
                    //System.println("Not this time - first event");
                }
            }


        } else if(Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId) {
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF)) {
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF)) {
                    // Channel closed, re-open
                    open();
                } else if( Ant.MSG_CODE_EVENT_RX_FAIL_GO_TO_SEARCH  == (payload[1] & 0xFF) ) {
                    searching = true;
                }
            } else {
                //It is a channel response.
            }
        }
    }

}