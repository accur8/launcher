package a8;




class HaxeOps {

    public static function asString(bytes: haxe.io.Bytes) {
        return bytes.getString(0, bytes.length);
    }

}

