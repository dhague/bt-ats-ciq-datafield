class BtAtsPowerCalculator {
    var power = 0;
    var observer = null;    /// callback method

    function notifyChange(observerMethod) {
        observer = observerMethod;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    const A =  0.290390167;
    const B = -0.0461311774;
    const C =  0.592125507;
    const D =  0.0;

    // 1.191 is the air density at which the coefficients above were determined
    const defaultAirDensity = 1.191;
    var airDensityCorrection = 0;
    //const airDensityCorrection = readKeyFloat(Application.getApp(), "airDensity", defaultAirDensity) / defaultAirDensity;

    // from Steven Sansonetti of Bike Technologies:
    //  This is a 3rd order polynomial, where P = A*v^3 + B*v^2 + C*v + d
    //  where v is speed in revs/sec and constants A, B, C & D are as defined above.
    function powerFromSpeed(revsPerSec) {
        if (airDensityCorrection == 0) {
            updateAirDensityCorrection();
        }
        var rs = revsPerSec;
        power = airDensityCorrection * (A*rs*rs*rs + B*rs*rs + C*rs + D);
        return power;
    }

    function updateAirDensityCorrection() {
        airDensityCorrection = readKeyFloat(Application.getApp(), "airDensity", defaultAirDensity) / defaultAirDensity;
        System.println("Air density correction: "+airDensityCorrection);
    }

    function onSpeedChange(revsPerSec) {
        if (observer) {
            observer.invoke(powerFromSpeed(revsPerSec));
        }
    }

    function readKeyFloat(myApp, key, thisDefault) {
        var value = myApp.getProperty(key);
        if(value == null || !(value instanceof Float)) {
            if(value != null) {
                value = value.toFloat();
            } else {
                value = thisDefault;
            }
        }
        return value;
    }

}
