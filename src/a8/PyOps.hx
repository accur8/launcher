package a8;



import python.lib.threading.Thread;
import python.Bytearray;


@:pythonImport("urllib.request")
extern class PyUrllibRequest {

    public static function urlopen(url:Dynamic, data:Dynamic): Dynamic;

}

class PyHttpAssist {

    public static function httpPost(url: String, postBody: Dynamic): String {
        var requestBodyStr = haxe.Json.stringify(postBody);
        var requestBody = new Bytearray(requestBodyStr, "utf8");
        var bytesResponse = PyUrllibRequest.urlopen(url, requestBody).read();
        var responseBody = new Bytearray(bytesResponse).decode("utf8");
        return responseBody;
    }

    public static function httpGet(url: String): String {
        var bytesResponse = PyUrllibRequest.urlopen(url, null).read();
        return new Bytearray(bytesResponse).decode("utf8");
    }

}

@:pythonImport("urllib.parse")
extern class PyUrllibParse {
    public static function urlparse(urlStr: String): Dynamic;
    public static function urlunparse(urlParseTuple: Dynamic): String;
}

@:pythonImport("shutil")
extern class PyShutil2 {

    public static function move(src:String, dst:String):Void;

    public static function which(cmd:String):String;

}

@:pythonImport("os")
extern class PyOs2 {

    public static function symlink(src: String, dst: String): Void;

    public static function execvpe(file: String, args: Array<String>, env: python.Dict<String,String>): Void;

    public static function readlink(src: String): String;
    
}


@:pythonImport("os.path")
extern class PyPath {

    public static function realpath(src: String): String;

}

@:pythonImport("sched")
extern class PySched {

    public static function scheduler(): PyScheduler;

}


extern class PyScheduler {

    public function enterabs(delay: Float, priority: Float, action: Void->Void): PyEvent;
    public function enter(delay: Float, priority: Float, action: Void->Void): PyEvent;
    public function cancel(event: PyEvent): Void;
    public function run(): Float;

}

extern class PyEvent {
}


@:tink
class PyOps {

    public static function toDict<A,B>(map: Map<A,B>): python.Dict<A,B> {
        var dict = new python.Dict();
        for ( k in map.keys()) {
            dict.set(k, map.get(k));
        }
        return dict;
    }

    public static function spawn(fn: Void->Void): Thread {

        var th = new Thread({target:fn});
        th.daemon = true;
        th.start();

        return th;
        
    }

}