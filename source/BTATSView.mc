using Toybox.WatchUi as Ui;
using Toybox.Sensor as Snsr;
using Toybox.System as System;

class BTATSView extends Ui.SimpleDataField {

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "BT-ATS Power";
        //Snsr.setEnabledSensov( [Snsr.SENSOR_BIKESPEED] );
        //Snsr.enableSensorEvents( method(:onSnsr) );
    }

/*    function onSnsr(sensor_info)
    {

        var HR = sensor_info.speed;
        var bucket;
        if( sensor_info.heartRate != null )
        {
            string_HR = HR.toString() + "bpm";

            //Add value to graph
            HR_graph.addItem(HR);
        }
        else
        {
            string_HR = "---bpm";
        }

        Ui.requestUpdate();
        
    }
*/    
    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    const A =  0.290390167;
    const B = -0.0461311774;
    const C =  0.592125507;
    const D =  0.0;
     
    function compute(info) {
    	System.println("info.currentSpeed is: "+info.currentSpeed);
    	var rs = info.currentSpeed / 2.1; // revs per second
		//System.println("Speed in revs/sec is "+rs);
        // from Steven Sansonetti of Bike Technologies:
        //  This is a 3rd order polynomial, where P = A*v^3 + B*v^2 + C*v + d
        //  where:
        return me.A*rs*rs*rs + me.B*rs*rs + me.C*rs + me.D;
    }

}