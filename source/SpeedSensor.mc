//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Ant as Ant;
using Toybox.Time as Time;
using Toybox.System as System;

class SpeedCadenceSensor extends Ant.GenericChannel {
    const SPEED_DEVICE_TYPE = 0x7B;
    const CADENCE_DEVICE_TYPE = 0x7A;
    const SPEED_CADENCE_DEVICE_TYPE = 0x79;

    hidden var chanAssign;

    var currentData;
    var previousData;
    var currentMessageTime;
    var previousMessageTime;
    var searching;
    var deviceCfg;


    var revsPerSec = 0.0;

    class SpeedCadenceData {
        var speedRevCount;
        var speedEventTime;
        var cadenceRevCount;
        var cadenceEventTime;

        function initialize() {
            speedRevCount = null;
            speedEventTime = null;
            cadenceRevCount = null;
            cadenceEventTime = null;
        }
    }

    class DataPage {
        function parseEventTime(payload, offset) {
           return (payload[offset] | (payload[offset+1] << 8)) / 1024f;
        }

        function parseRevCount(payload, offset) {
           return payload[offset] | (payload[offset+1] << 8);
        }
    }

    class SpeedDataPage extends DataPage {
        function parse(payload, data) {
            data.speedEventTime = parseEventTime(payload, 4);
            data.speedRevCount = parseRevCount(payload, 6);
        }
    }

    class CadenceDataPage extends DataPage {
        function parse(payload, data) {
            data.cadenceEventTime = parseEventTime(payload, 4);
            data.cadenceRevCount = parseRevCount(payload, 6);
        }
    }

    class SpeedCadenceDataPage extends DataPage {
        function parse(payload, data) {
            //System.println("SpeedCadenceDataPage.parse()");
            //System.print("parse cadence event time: ");
            data.cadenceEventTime = parseEventTime(payload, 0);
            //System.println(data.cadenceEventTime);
            //System.print("parse cadence rev count: ");
            data.cadenceRevCount = parseRevCount(payload, 2);
            //System.println(data.cadenceRevCount);
            //System.print("parse speed event time: ");
            data.speedEventTime = parseEventTime(payload, 4);
            //System.println(data.speedEventTime);
            //System.print("parse speed rev count: ");
            data.speedRevCount = parseRevCount(payload, 6);
            //System.println(data.speedRevCount);
        }
    }

    function initialize() {

        // Get the channel
        chanAssign = new Ant.ChannelAssignment(
            Ant.CHANNEL_TYPE_RX_NOT_TX,
            Ant.NETWORK_PLUS);
        GenericChannel.initialize(method(:onMessage), chanAssign);

        var sensorType = Application.getApp().getProperty("antSpeedSensorType");
        System.println("antSpeedSensorType: "+sensorType);

        System.println("antSpeedSensorId: "+Application.getApp().getProperty("antSpeedSensorId"));

        var period = 0;
        if (sensorType == SPEED_DEVICE_TYPE) {
            period = 8118;
        } else if (sensorType == CADENCE_DEVICE_TYPE) {
            period = 8102;
        } else if (sensorType == SPEED_CADENCE_DEVICE_TYPE) {
            period = 8086;
        }

        // Set the configuration
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => Application.getApp().getProperty("antSpeedSensorId"),
            :deviceType => sensorType,
            :transmissionType => 0,
            :messagePeriod => period,
            :radioFrequency => 57,              //Ant+ Frequency
            :searchTimeoutLowPriority => 10,    //Timeout in 25s
            :searchThreshold => 0} );           //Pair to all transmitting sensors
        GenericChannel.setDeviceConfig(deviceCfg);

        revsPerSec = 0.0;
        searching = true;
        previousData = null;
        currentData = null;

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

    // Hopefully this will be the template for sending out a power message (maybe in a PowerSensor class)
    // - but we will need GenericChannel to be able to both receive Speed and send Power
    function setTime() {
        if( !searching && ( data.utcTimeSet ) ) {
            //Create and populat the data payload
            var payload = new [8];
            payload[0] = 0x10;  //Command data page
            payload[1] = 0x00;  //Set time command
            payload[2] = 0xFF; //Reserved
            payload[3] = 0; //Signed 2's complement value indicating local time offset in 15m intervals

            //Set the current time
            var moment = Time.now();
            for (var i = 0; i < 4; i++) {
                payload[i + 4] = ((moment.value() >> i) & 0x000000FF);
            }

            //Form and send the message
            var message = new Ant.Message();
            message.setPayload(payload);
            GenericChannel.sendAcknowledge(message);
        }
    }

    function stopped() {
        // Question: how to detect if we are stopped?
        // Answer: heuristic - record timestamps of messages. If > 1 second between messages with
        // no change in speed data then we are stopped.

        // TODO
        return false;
    }

    //(:test)
    function onMessageTest(logger) {
        // Simulate a few speed/cadence sensor messages
        var msg = new Ant.Message();
        msg.messageId = 0x4E;
        msg.deviceNumber = 41558;
        msg.deviceType = 0x79;
        msg.setPayload([0x55, 0xC6, 0x45, 0x50, 0xF4, 0x6F, 0xBB, 0x3A]);
        onMessage(msg);
        msg.setPayload([0x55, 0xC6, 0x45, 0x50, 0xF3, 0x71, 0xBF, 0x3A]);
        onMessage(msg);
        msg.setPayload([0x55, 0xC6, 0x45, 0x50, 0xF1, 0x72, 0xC1, 0x3A]);
        onMessage(msg);
        return revsPerSec > 0.0; // returning true indicates pass, false indicates failure
    }

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