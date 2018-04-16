package a8;


class AddShebang {

    public static function apply(path: String, shebang: String) {
        haxe.macro.Context.onAfterGenerate(function() {
            impl(path, shebang);
        });
    }

    static function impl(path: String, shebang: String) {
        var contents = sys.io.File.getContent(path);
        sys.io.File.saveContent(path, shebang + "\n" + contents);
    }
}