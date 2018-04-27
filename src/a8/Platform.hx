package a8;


#if macro


#else

import a8.PyOps;

#end



class PlatformOps {

  public static var instance(default, null) = 
#if macro
    new NekoPlatform();
#else
    new PythonPlatform();
#end

}

/**
  * a class to delegate the various target platform things to
  */
interface Platform {

    function executablePath(): Path;
    function isFile(path: Path): Bool;
    function spawn(threadName: String, fn: Void->Void): Void;
    function moveTo(source: Path, target: Path): Void;

}

class AbstractPlatform {

    public function isFile(path: Path): Bool {
        var e = sys.FileSystem.exists(path.toString());
        var d = sys.FileSystem.isDirectory(path.toString());
        return e && !d;
    }

    public function spawn(threadName: String, fn: Void->Void): Void {
        throw new a8.Exception("TODO ??? implement me");
    }

    public function moveTo(source: Path, target: Path): Void {
        throw new a8.Exception("TODO ??? implement me");
    }
}

#if macro

class NekoPlatform extends AbstractPlatform implements Platform {

    public function new() {
    }

    public function executablePath(): Path {
        return new Path(Sys.executablePath());
    }

}

#else

class PythonPlatform extends AbstractPlatform implements Platform {

    public function new() {
    }

    public function executablePath(): Path {
        return new Path(python.lib.Sys.argv[0]);
    }

    override public function isFile(path: Path): Bool {
        return python.lib.os.Path.isfile(path.toString());
    }

    override public function spawn(threadName: String, fn: Void->Void): Void {
        var th = new python.lib.threading.Thread({target:fn});
        th.start();        
    }

    override public function moveTo(source: Path, target: Path): Void {
        PyShutil2.move(source.toString(), target.toString());
    }

}

#end



