using Toybox.Application as App;

class BTATSApp extends App.AppBase {

    var scSensor;
    var pSensor;

    function initialize() {
        AppBase.initialize();
        System.println("#### BTATSApp.initialize() ####");
    }

    // onStart() is called on application start up
    function onStart(state) {
        System.println("BTATSApp.onStart()");
/*
        try {
            //Create the power sensor object and open it
            pSensor = new PowerTxSensor();
            pSensor.open();
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            Sys.println("pSensor: "+e.getErrorMessage());
            pSensor = null;
        }
        // Create a power calculator and notify the power sensor whenever power changes
        powerCalculator = new BtAtsPowerCalculator(pSensor.method(:onPowerChange));
*/
        // Create a power calculator and record to the FIT file whenever power changes

        try {
            //Create the speed sensor object and open it
            scSensor = new SpeedCadenceSensor();
            scSensor.open();
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            Sys.println("scSensor: "+e.getErrorMessage());
            scSensor = null;
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        System.println("BTATSApp.getInitialView()");
        return [ new BTATSView(scSensor) ];
    }

}