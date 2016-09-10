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

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    const A =  0.290390167;
    const B = -0.0461311774;
    const C =  0.592125507;
    const D =  0.0;

    var count=0;

    function compute(info) {
        //System.println("info.currentSpeed is: "+info.currentSpeed);
        //var rs = info.currentSpeed / 2.1; // revs per second
        if (scSensor != null) {
            var rs = scSensor.revsPerSec; // revs per second
            // from Steven Sansonetti of Bike Technologies:
            //  This is a 3rd order polynomial, where P = A*v^3 + B*v^2 + C*v + d
            //  where v is speed in revs/sec and constants A, B, C & D are as defined above.
            var power = A*rs*rs*rs + B*rs*rs + C*rs + D;
            System.println("Power: "+power);
            return power;
        } else {
            return 0.0;
        }
    }

}