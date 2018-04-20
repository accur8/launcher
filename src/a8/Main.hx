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
import a8.LogRoller;
using tink.CoreApi;

@:tink 
class Main {

    public static var scheduler = {
        var s = PySched.scheduler();
        PyOps.spawn({ [] =>
            while(true) {
                s.run();
                python.lib.Time.sleep(1);
            }
        });
        s;
    }


    public static function main(): Void {

        var execPath = PathOps.executablePath();

        var appName = execPath.file;
        var configFile = execPath.parent().entry(execPath.file + ".json");

        var config: LaunchConfig = Json.parse(configFile.readText());

        if ( config.quiet == null ) {
            config.quiet = false;
        }
        if ( config.logRollers == null ) {
            config.logRollers = [];
        }

        var launcher = 
            new Launcher(
                config,
                appName,
                timestampStr()
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



@:tink
class Launcher {

    var config: LaunchConfig;
    public var appName: String;
    public var timestampStr: String;

    @:lazy var installDir: Path = initDirectory(config.installDir, null, a8.PathOps.path(python.lib.Os.getcwd()));
    @:lazy var logsDir: Path = initDirectory(config.logsDir, "logs", installDir);
    @:lazy var logArchivesDir: Path = initDirectory("archives", null, logsDir, true);

    public var pipedStdout: PipedStream;
    public var pipedStderr: PipedStream;
    var logRollers: Array<LogRoller>;

    static function initDirectory(configEntry: String, secondEntry: String, basePath: Path, ?makeDirectory: Bool): Path {
        var entry = if ( configEntry != null ) configEntry else secondEntry;
        var d: Path = 
            if ( entry == null ) {
                basePath;
            } else {
                var asPath = PathOps.path(entry);
                if (asPath.isAbsolute() ) {
                    asPath;
                } else {
                    basePath.entry(entry);
                }
            }
        if ( makeDirectory && !d.exists() ) {
            d.makeDirectories();
        }
        return d;
    }

    public function new(config: LaunchConfig, appName: String, timestampStr: String) {

        this.config = config;
        this.appName = appName;
        this.timestampStr = timestampStr;

    }

    public function logDetail(msg: String): Void {
        if ( !config.quiet ) {
            _log(msg, pipedStdout);
        }
    }
    
    function logError(msg: String): Void {
        _log("ERROR - " + msg, pipedStderr);
    }
    
    function logWarn(msg: String): Void {
        _log("WARN - " + msg, pipedStderr);
    }

    private function _log(msg: String, pipe: PipedStream): Void {
        if ( pipe != null ) {
            pipe.log(msg);
        } else {
            trace(msg);
        }
    }

    function archiveOldLogs(): Void {

        var prefix = appName + ".";
        var suffix1 = ".details";
        var suffix2 = ".errors";

        var filesToArchive = 
            logsDir
                .files()
                .filter([f] => {
                    var filename = f.basename();
                    (
                        filename.startsWith(prefix) &&
                        (filename.endsWith(suffix1) || filename.endsWith(suffix2)));
                });

        archiveLogFiles(filesToArchive);

    }

    public function archiveLogFiles(files: Array<Path>): Void {

        var archivedFiles = 
            files
                .map([f] => {
                    var target = logArchivesDir.entry(f.basename());
                    target.delete();
                    f.moveTo(target);
                    target;
                });

        trace("archiving log files -- " + archivedFiles);

        function gzipFiles() {
            archivedFiles.iter(function(f) {
                Subprocess.call(["gzip", "-f", f.realPathStr()]);
            });
        }

        PyOps.spawn(gzipFiles);

    }

    function resolveStandardArgs(stdlauncher: ArgsLaunchConfig): ResolvedArgs {
        return {
            args: stdlauncher.args,
            env: null,
            cwd: null,
            executable: null
        };
    }

    function resolveJvmLaunchArgs(jvmlauncher: JvmLaunchConfig): ResolvedArgs {

        var installInventoryFile = installDir.entry("install-inventory.json");

        var config: InstallInventory = Json.parse(installInventoryFile.readText());

        var launcherD: Dynamic = jvmlauncher;

        installDir.entry("lib").entries().iter(function (e) {
            var p = e.realPathStr();
            if ( p.endsWith(".jar") || e.isDir() ) {
                config.classpath.push(p);
            } 
        });
        var classpath = config.classpath.join(":");

        var args = new Array<String>();

        var symlinkName = "j_" + appName;
        var symlinkParent = installDir;
        var javaAppNameSymLink = symlinkParent.realPathStr() + "/" + symlinkName;
        var javaAppNameSymLinkPath = PathOps.path(javaAppNameSymLink);
        var cmd = 
            if ( !javaAppNameSymLinkPath.isFile() ) {
                var javaExec = PyShutil2.which("java");
                trace("creating symlink " + javaExec + " --> " + javaAppNameSymLink);
                PyOs2.symlink(javaExec, javaAppNameSymLink);
                if ( javaAppNameSymLinkPath.isFile() ) {
                    "./" + symlinkName;
                } else {
                    "java";
                }
            } else {
                "./" + symlinkName;
            }

        args.push(cmd);

        args.push("-DappName=" + appName);

        if ( launcherD.jvmArgs != null ) 
            jvmlauncher.jvmArgs.iter(function(jvmArg) {
                args.push(jvmArg);
            });

        // trace(classpath);

        args.push(jvmlauncher.mainClass);

        if ( launcherD.args != null ) 
            jvmlauncher.args.iter(function(arg) {
                args.push(arg);
            });

        var env = python.lib.Os.environ;

        var newEnv = env.copy();

        // trace('set -x CLASSPATH "' + classpath + '"');

        newEnv.set("CLASSPATH", classpath);
        newEnv.set("LAUNCHER_INSTALL_DIR", installDir.realPathStr());
        newEnv.set("LAUNCHER_WORKING_DIR", python.lib.Os.getcwd());
        newEnv.set("LAUNCHER_EXEC_PATH", PathOps.executablePath().realPathStr());

        return {
            args: args,
            env: newEnv,
            cwd: installDir.realPathStr(),
            executable: "./" + symlinkName
        };

    }


    public function runAndWait(): Void {

        logDetail("installDir = " + installDir);
        logDetail("logsDir = " + logsDir);
        logDetail("logArchivesDir = " + logArchivesDir);

        archiveOldLogs();

        var popenArgs = 
            if ( config.kind == "jvm" ) 
                resolveJvmLaunchArgs(cast config);
            else if ( config.kind == "args" ) 
                resolveStandardArgs(cast config);
            else 
                throw "unable to resolve config kind " + config.kind;

        logDetail("running -- " + popenArgs.args);

        var popen = new Popen(popenArgs.args, null, popenArgs.executable, null, Subprocess.PIPE, Subprocess.PIPE, null, false, false, popenArgs.cwd, popenArgs.env);

        function firstIO(out: OutputStream): Void {
            out.write("first output at " + Main.timestampStr() + "\n");
        }

        logDetail("setting up pipes");
        this.pipedStdout = new PipedStream(this, popen.stdout.asInputStream(), PySys.stdout, "details", firstIO);
        this.pipedStderr = new PipedStream(this, popen.stderr.asInputStream(), PySys.stderr, "errors", firstIO);

        this.pipedStdout.start();
        this.pipedStderr.start();

        // logDetail("pipes setup");

        logDetail("initializeLogRollers");
        initializeLogRollers();
        logDetail("initializeLogRollers complete");

        // logDetail("waiting for process to complete");
        popen.wait();
        // logDetail("process completed with exit code " + popen.returncode);

        this.pipedStdout.close();
        this.pipedStdout.close();

    }


    function initializeLogRollers() {
        this.logRollers = 
            config
                .logRollers
                .map([lr] => LogRollerOps.fromConfig(lr, this));
        this.logRollers.iter([i]=>i.init());
    }

}

@:tink
class PipedStream {
    
    var launcher: Launcher = _;
    var processInput: InputStream = _;
    var stdxxx: TextIOBase = _;
    var fileExtension: String = _;
    var firstIO: OutputStream->Void = _;

    var fileOutputPath: Path;
    var fileOut: OutputStream;
    var pipe: Pipe;

    var teeOut: OutputStream;

    var started = false;

    public function start() {
        if ( !started ) {
            this.started = true;
            this.fileOutputPath = outputFile(launcher.timestampStr);
            this.fileOut = StreamOps.fileOutputStream(fileOutputPath.realPathStr());
            this.teeOut = new TeeOutputStream([this.fileOut, stdxxx.asOutputStream()]);
            this.pipe = new Pipe(processInput, teeOut, firstIO);
            this.pipe.run();
        }
    }

    function outputFile(timestampStr: String): Path {
        return launcher.logsDir.entry(launcher.appName + "." + timestampStr + "." + fileExtension);
    }

    public function log(msg: String) {
        if ( teeOut != null ) {
            try {
                teeOut.write(msg);
                teeOut.write("\n");
            } catch(e: Dynamic) {
                trace("error logging - " + e);
            }
        }
    }

    public function rollover(timestampStr: String) {
        // a role would be done as follows
        //    1) get the pipedStream using a new file output
        var newFileOutputPath = outputFile(timestampStr);
        var newfileOut = StreamOps.fileOutputStream(launcher.logsDir.entry(launcher.appName + "." + timestampStr + "." + fileExtension).realPathStr());
        this.pipe.replaceOutput = [oldOut] => {
            oldOut.close();
            newfileOut;
        }

        //    2) move the old file to archives and gzip them
        var oldFileoutputPath = this.fileOutputPath;
        this.fileOutputPath = newFileOutputPath;
        launcher.archiveLogFiles([oldFileoutputPath]);

        //    4) trigger any kind of disk space based log rollers

    }

    public function close() {
        fileOut.close();
    }

}

typedef ResolvedArgs = {
    var args: Array<String>;
    var env: python.Dict<String,String>;
    var cwd: String;
    var executable: String;
}

typedef LaunchConfig = {
    var kind: String;
    @:optional var quiet: Bool;
    @:optional var installDir: String;
    @:optional var logsDir: String;
    @:optional var logRollers: Array<Dynamic>;
}

typedef JvmLaunchConfig = {
    // var groupId: String;
    // var artifactId: String;
    // var version: String;
    var mainClass: String;
    @:optional var jvmArgs: Array<String>;
    @:optional var args: Array<String>;
    @:optional var webappExplode: Bool;
    @:optional var libDirKind: String;
    @:optional var branch: String;
}


typedef ArgsLaunchConfig = {
    var args: Array<String>;
}

typedef InstallInventory = {
    var appInstallerConfig: AppInstallerConfig;
    var classpath: Array<String>;
}

typedef AppInstallerConfig = {
    var groupId: String;
    var artifactId: String;
    var version: String;
    var installDir: String;
    var libDirKind: String;
    var webappExplode: Bool;
}



