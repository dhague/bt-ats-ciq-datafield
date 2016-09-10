class BtAtsPowerCalculator {
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

    // from Steven Sansonetti of Bike Technologies:
    //  This is a 3rd order polynomial, where P = A*v^3 + B*v^2 + C*v + d
    //  where v is speed in revs/sec and constants A, B, C & D are as defined above.
    function powerFromSpeed(revsPerSec) {
        var rs = revsPerSec;
        var power = A*rs*rs*rs + B*rs*rs + C*rs + D;
        return power;
    }

    function onSpeedChange(revsPerSec) {
        if (observer) {
            observer.invoke(powerFromSpeed(revsPerSec));
        }
    }
}