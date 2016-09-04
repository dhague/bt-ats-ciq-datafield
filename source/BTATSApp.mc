using Toybox.Application as App;

class BTATSApp extends App.AppBase {

    var scSensor;
    
    function initialize() {
        AppBase.initialize();
        System.println("#### BTATSApp.initialize() ####");
    }

    // onStart() is called on application start up
    function onStart(state) {
        System.println("BTATSApp.onStart()");
        try {
            //Create the sensor object and open it
            scSensor = new SpeedCadenceSensor();
            scSensor.open();
        } catch(e instanceof Ant.UnableToAcquireChannelException) {
            Sys.println(e.getErrorMessage());
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