package a8;



import haxe.PosInfos;

class Exception {

    public static function thro(message: String) {
        throw new Exception(message);
    }

    public var message(default,null): String;
    public var causedBy(default,null): Option<Exception>;
    public var callStack(default,null): Array<haxe.CallStack.StackItem>;
    public var posInfos(default,null): PosInfos;

    public function new(message: String, ?causedBy: Exception, ?posInfos: PosInfos) {
        this.message = message;
        this.causedBy = causedBy.toOption();
        this.callStack = haxe.CallStack.callStack();
        this.posInfos = posInfos;
    }

    public function toString(): String {
        return 
            posInfos.fileName + ":" 
                + posInfos.lineNumber + " " 
                + message + "\n" 
                + callStack.asString("    ")
            ;
    }

    public function rethrow(context: String, ?posInfos: PosInfos): Void {
        throw new Exception(context, this, posInfos);
    }

}
