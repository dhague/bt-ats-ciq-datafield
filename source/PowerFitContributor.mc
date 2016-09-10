using Toybox.FitContributor as Fit;

class PowerFitContributor {
    var mCurrentPower;

    function initialize(dataField) {
        // 0 maps to <fitField id="0"> in resources.xml
        mCurrentPower = dataField.createField("power", 0, Fit.DATA_TYPE_UINT16,
            { :nativeNum=>7, :mesgType=>Fit.MESG_TYPE_RECORD, :units=>"W" });
        mCurrentPower.setData(0);
    }

    function record(power) {
        mCurrentPower.setData(power);
    }
}
