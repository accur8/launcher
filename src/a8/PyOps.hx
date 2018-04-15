package a8;


import python.lib.threading.Thread;



@:pythonImport("shutil")
extern class Shutil2 {

    public static function move(src:String, dst:String):Void;

}



class PyOps {

    public static function spawn(fn: Void->Void): Thread {

        var th = new Thread({target:fn});
        th.start();

        return th;
        
    }

}