package a8;





class Logger {

    public static var traceEnabled: Bool = false;

    public static function trace(msg: String, ?posInfo: haxe.PosInfos): Void {
        if ( traceEnabled ) {
            haxe.Log.trace("TRACE - " + msg, posInfo);
        }
    }

    public static function warn(msg: String, ?posInfo: haxe.PosInfos): Void {
        haxe.Log.trace("WARN - " + msg, posInfo);
    }


}
