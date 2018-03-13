package a8;


import haxe.io.Path;
import haxe.io.Bytes;
import sys.io.File;
import sys.FileSystem;


class PathOps {

    public static function path(p: String): Path {
        return new Path(p);
    }

    /** This is the path to the program invoked from the command line.
      *  i.e. without symlinks resolved.
      *
      */ 
    public static function executablePath(): Path {
        return new Path(python.lib.Sys.argv[0]);
    }

    /** 
      * This is the canonical location of the executablePath.
      *
      */
    public static function programPath(): Path {
        return new Path(Sys.programPath());
    }

    public static function readText(path: Path): String {
        return File.getContent(path.toString());
    }

    public static function readBytes(path: Path): Bytes {
        return File.getBytes(path.toString());
    }

    public static function exists(path: Path): Bool {
        return FileSystem.exists(path.toString());
    }

    public static function isAbsolute(path: Path): Bool {
        return Path.isAbsolute(path.toString());
    }

    public static function writeBytes(path: Path, bytes: Bytes): Void {
        File.saveBytes(path.toString(), bytes);
    }

    public static function writeText(path: Path, text: String): Void {
        File.saveContent(path.toString(), text);
    }

    public static function parent(path: Path): Path {
        switch(path.dir) {
            case null:
                if ( isAbsolute(path)) {
                    return null;
                } else {
                    return new Path(FileSystem.fullPath("."));
                }
            case d:
                return new Path(d);
        }
    }

    @:op(A / B)
    public static function entry(dir: Path, name: String): Path {
        var separator = if (dir.backslash) "" else "/";
        return new Path(dir.toString() + separator + name);
    }

}