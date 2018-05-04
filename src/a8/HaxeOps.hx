package a8;


import haxe.CallStack;
import haxe.ds.StringMap;


@:tink
class HaxeOps {

    public static function asString(bytes: haxe.io.Bytes) {
        return bytes.getString(0, bytes.length);
    }

    public static function toMap<A>(iterable: Iterable<A>, keyFn: A->String): StringMap<A> {
        var map = new StringMap<A>();
        iterable.iter(function(a) { map.set(keyFn(a), a); });
        return map;
    }

    public static function isDigit(ch: String): Bool {
        return 
            ch.length == 1 && ch >= "0" && ch <= "0"
            ;
    }

    public static function isAlpha(ch: String): Bool {
        return 
            ch.length == 1 && 
                ((ch >= "A" && ch <= "Z")
                || (ch >= "a" && ch <= "z"))
            ;
    }

    public static function isWhitespace(ch: String): Bool {
        return 
            switch ch {
                case " " | "\n" | "\t" | "\r":
                    true;
                default:
                    false;
            }
    }

    public static function isHaxeIdentifierFirstChar(ch: String): Bool {
        return
            ch.length == 1 &&
                (
                    isAlpha(ch)
                    || ch == "_"
                )
            ;
    }

    public static function isHaxeIdentifierSecondChar(ch: String): Bool {
        return isHaxeIdentifierFirstChar(ch) || isDigit(ch);
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

    public static function toMap<A>(iterable: Iterable<a8.Tuple2<String,A>>): StringMap<A> {
        var map = new StringMap<A>();
        for ( t in iterable ) {
            map.set(t._1(), t._2());
        }
        return map;
    }
}

