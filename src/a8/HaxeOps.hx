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

