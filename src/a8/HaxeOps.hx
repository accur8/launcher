package a8;


import haxe.CallStack;



@:tink
class HaxeOps {

    public static function asString(bytes: haxe.io.Bytes) {
        return bytes.getString(0, bytes.length);
    }

}



@:tink
class HaxeOps2 {

    public static function asString(stack: Array<StackItem>, ?indent: String): String {
        if ( indent == null ) {
            indent = "";
        }
        var s = stack
            .map(function(si) { return indent + si; })
            .join("\n");
        return s;
    }

}

