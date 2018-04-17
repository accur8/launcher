package a8;


import haxe.io.Path;
import haxe.io.Bytes;
import sys.io.File;
import sys.FileSystem;
import python.lib.Os;
import a8.PyOps;

class PathOps {

    public static function path(p: String): Path {
        return new Path(p);
    }

    /** 
      *  This is the path to the program invoked from the command line.
      *  i.e. without symlinks resolved.
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

    public static function makeDirectories(path: Path): Void {
        Os.makedirs(path.toString());
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

    public static function files(parentDir: Path): Array<Path> {
        return 
            entries(parentDir)
                .filter(function (e) { 
                    return isFile(e); 
                });
    }

    /**
     *   Just the filename portion of the path like the unix basename tool
     */
    public static function basename(path: Path): String {
        var suffix = if ( path.ext == null ) "" else "." + path.ext;
        return path.file + suffix;
    }

    public static function moveTo(source: Path, target: Path): Void {
        PyShutil2.move(source.toString(), target.toString());
    }

    public static function entries(parentDir: Path): Array<Path> {
        var sep = if ( parentDir.backslash ) "" else "/";
        return 
            Os
                .listdir(realPathStr(parentDir))
                .map(function(e) {
                    return new Path(parentDir.toString() + sep + e);
                });
    }

    public static function isFile(path: Path): Bool {
        return python.lib.os.Path.isfile(path.toString());
    }

    public static function isDir(path: Path): Bool {
        return python.lib.os.Path.isdir(path.toString());
    }

    public static function realPathStr(path: Path): String {
        return python.lib.os.Path.realpath(path.toString());
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

    public static function entry(dir: Path, name: String): Path {
        var separator = if (dir.backslash) "" else "/";
        return new Path(dir.toString() + separator + name);
    }

}