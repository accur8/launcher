package a8;


import python.lib.threading.Thread;


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