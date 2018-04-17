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

}


@:pythonImport("sched")
extern class PySched {

    public static function scheduler(): PyScheduler;

}


extern class PyScheduler {

    public function enterabs(delay: Float, priority: Float, action: Void->Void): PyEvent;
    public function enter(delay: Float, priority: Float, action: Void->Void): PyEvent;
    public function cancel(event: PyEvent): Void;

}

extern class PyEvent {
}


class PyOps {

    public static function spawn(fn: Void->Void): Thread {

        var th = new Thread({target:fn});
        th.start();

        return th;
        
    }

}