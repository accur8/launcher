package a8;


import python.lib.threading.Thread;



@:pythonImport("shutil")
extern class PythonShutil2 {

    public static function move(src:String, dst:String):Void;

    public static function which(cmd:String):String;

}

@:pythonImport("os")
extern class PythonOs2 {

    public static function symlink(src: String, dst: String): Void;

}



class PyOps {

    public static function spawn(fn: Void->Void): Thread {

        var th = new Thread({target:fn});
        th.start();

        return th;
        
    }

}