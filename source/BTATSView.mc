using Toybox.WatchUi as Ui;
using Toybox.Sensor as Snsr;
using Toybox.System as System;

class BTATSView extends Ui.SimpleDataField {

    var scSensor;
    var powerFitContributor;
    var powerCalculator;

    // Set the label of the data field here.
    function initialize(scSensorParam) {
        System.println("BTATSView.initialize(scSensor)");
        SimpleDataField.initialize();
        label = "BT-ATS Power";
        scSensor = scSensorParam;
        powerFitContributor = new PowerFitContributor(self);
        powerCalculator = new BtAtsPowerCalculator();
        scSensor.notifyChange(powerCalculator.method(:onSpeedChange));
        powerCalculator.notifyChange(powerFitContributor.method(:record));
    }

    function compute(info) {
        if (powerCalculator != null) {
            var power = powerCalculator.getPower().toNumber();
            System.println("W: "+power);
            return power;
        } else {
            return 0;
        }
    }

}