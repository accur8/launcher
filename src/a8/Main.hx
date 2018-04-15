package a8;


import sys.FileSystem;
import a8.Streams;

using Lambda;
using a8.PathOps;
using a8.StreamOps;
using StringTools;

import haxe.Json;
import python.lib.subprocess.Popen;
import python.lib.Subprocess;
import python.lib.io.FileIO;
import python.lib.io.TextIOBase;
import python.Bytes;
import a8.parser.Position;
import a8.parser.Parser;
import python.Lib.PySys;
import haxe.io.Path;
import a8.PyOps;
import python.lib.Subprocess;

class Main {

    public static function main(): Void {

        var execPath = PathOps.executablePath();

        var appName = execPath.file;
        var configFile = execPath.parent().entry(execPath.file + ".json");

        var config: LaunchConfig = Json.parse(configFile.readText());

        var logsDir = PathOps.path("logs");
        var logArchivesDir = logsDir.entry("archives");
        if ( !logArchivesDir.exists() )
            logArchivesDir.makeDirectories();

        var launcher = 
            new Launcher(
                config,
                appName,
                timestampStr(),
                logsDir,
                logArchivesDir
            );

        launcher.runAndWait();

    }

    public static function timestampStr(): String {
        var now = Date.now();
        function pad(i: Int): String {
            return ("" + i).lpad("0", 2);
        }
        return now.getFullYear() + pad(now.getMonth()) + pad(now.getDate()) + "_" + pad(now.getHours()) + pad(now.getMinutes()) + pad(now.getSeconds());
    }

}




class Launcher implements ValueClass {

    var config: LaunchConfig;
    var appName: String;
    var timestampStr: String;
    var logsDir: Path;
    var logArchivesDir: Path;


    public function archiveOldLogs(): Void {

        var prefix = appName + ".";
        var suffix1 = ".details";
        var suffix2 = ".errors";

        var filesToArchive = 
            logsDir
                .files()
                .filter(function(f) {
                    var filename = f.basename();
                    return 
                        filename.startsWith(prefix) &&
                        (filename.endsWith(suffix1) || filename.endsWith(suffix2));
                });

        var archivedFiles = 
            filesToArchive
                .map(function(f) {
                    var target = logArchivesDir.entry(f.basename());
                    f.moveTo(target);
                    return target;
                });

        function gzipFiles() {
            archivedFiles.iter(function(f) {
                Subprocess.call(["gzip", f.realPathStr()]);
            });
        }

        PyOps.spawn(gzipFiles);

    }


    public function runAndWait(): Void {

        archiveOldLogs();

        var popen = new Popen(config.args, null, null, null, Subprocess.PIPE, Subprocess.PIPE);

        function firstIO(out: OutputStream): Void {
            out.write("first output at " + Main.timestampStr() + "\n");
        }

        var stdoutTee = tee(PySys.stdout, "details");
        var pipeStdout = new Pipe(popen.stdout.asInputStream(), stdoutTee, firstIO);
        pipeStdout.run();

        var stderrTee = tee(PySys.stderr, "errors");
        var pipeStderr = new Pipe(popen.stderr.asInputStream(), stderrTee, firstIO);
        pipeStderr.run();

        popen.wait();

        stdoutTee.close();
        stderrTee.close();

    }


    function tee(textIOBase: TextIOBase, extension: String): OutputStream {
        return
            new TeeOutputStream([
                StreamOps.fileOutputStream(logsDir.entry(appName + "." + timestampStr + "." + extension).realPathStr()),
                textIOBase.asOutputStream()
            ]);
    }


}


typedef LaunchConfig = {
  var args: Array<String>;
}


