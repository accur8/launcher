package a8;


import haxe.macro.Context;

class MacroPlay {

    public macro static function test(e0:ExprOf<String>, e1:ExprOf<String>) {
        // trace(e.toString()); // @:this this
        // TInst(String,[])
        trace(Context.typeof(e0));
        trace(Context.typeof(e1));
        return e0;
    }

    public static function myVoid(): Void {
    }

    public static function run(): Void {
        test(myVoid(), myVoid());
    }

}