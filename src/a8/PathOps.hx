package a8;


import haxe.io.Path;
import haxe.io.Bytes;
import sys.io.File;
import sys.FileSystem;
import a8.Platform;

@:tink
class PathOps {

    public static function timestampStr(): String {
        var now = Date.now();
        function pad(i: Int): String {
            return ("" + i).lpad("0", 2);
        }
        return now.getFullYear() + pad(now.getMonth()) + pad(now.getDate()) + "_" + pad(now.getHours()) + pad(now.getMinutes()) + pad(now.getSeconds());
    }

    public static function path(p: String): Path {
        return new Path(p);
    }

    public static function symlinkChain(p: Path): Array<Path> {
        var paths = [];
        function impl(thePath: Path) {
            paths.push(absPath(thePath));
            if ( python.lib.os.Path.islink(thePath.toString()) ) {
                var relativeLink = PyOs2.readlink(thePath.toString());
                var absoluteLink = 
                    if ( python.lib.os.Path.isabs(relativeLink) )
                        relativeLink;
                    else
                        python.lib.os.Path.join(parent(thePath).toString(), relativeLink);
                var p = path(absoluteLink);
                impl(p);
            }
        }
        impl(p);
        return paths;
    }

    /** 
      *  This is the path to the program invoked from the command line.
      *  i.e. without symlinks resolved.
      */
    public static function executablePath(): Path {
        return a8.PlatformOps.instance.executablePath();
    }

    public static function userHome(): Path {
        return new Path(Sys.environment().get("HOME"));
    }

    public static function absPath(p: Path): Path {
        return PlatformOps.instance.absPath(p);
    }

    public static function name(p: Path): String {
        return 
            if ( p.ext == null ) {
                p.file;
            } else {
                p.file + "." + p.ext;
            }
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

    public static function readLines(path: Path): Array<String> {
        return readText(path).split("\n");
    }

    public static function makeDirectories(path: Path): Void {
        sys.FileSystem.createDirectory(path.toString());
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
        a8.PlatformOps.instance.moveTo(source, target);
    }

    public static function deleteFile(source: Path): Void {
        if ( exists(source) ) {
            sys.FileSystem.deleteFile(source.toString());
        }
    }

    public static function entries(parentDir: Path): Array<Path> {
        var sep = if ( parentDir.backslash ) "" else "/";
        return 
            if ( exists(parentDir) ) 
                sys.FileSystem
                    .readDirectory(realPathStr(parentDir))
                    .map(function(e) {
                        return new Path(parentDir.toString() + sep + e);
                    });
            else
                [];
    }

    public static function isFile(path: Path): Bool {
        return PlatformOps.instance.isFile(path);
    }

    public static function isDir(path: Path): Bool {
        return sys.FileSystem.isDirectory(path.toString());
    }

    public static function realPathStr(path: Path): String {
        return sys.FileSystem.fullPath(path.toString());
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

    public static function outputStream(p: Path): a8.Streams.OutputStream {
        return StreamOps.fileOutputStream(realPathStr(p));
    }

    public static function readProperties(p: Path, ?failOnNotFound: Bool): StringMap<String> {
        var rf = failOnNotFound.toOption().getOrElse(false);
        var exists = p.exists();
        return 
            if ( !exists && !rf ) {
                new StringMap();
            } else {
                p.readLines()
                    .flatMap(function(line) {
                        var a = line.split("=");
                        return 
                            if ( a.length == 2 ) {
                                [new Tuple2(a[0], a[1])];
                            } else {
                                [];
                            }
                    })
                    .toMap();
            }
    }

}





