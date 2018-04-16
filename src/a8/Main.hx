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

    function resolveStandardArgs(stdlauncher: ArgsLaunchConfig): ResolvedArgs {
        return {
            args: stdlauncher.args,
            env: null,
            cwd: null,
            executable: null
        };
    }

    function resolveJvmLaunchArgs(jvmlauncher: JvmLaunchConfig): ResolvedArgs {

        var installDir = PathOps.path(jvmlauncher.installDir);
        var installInventoryFile = installDir.entry("install-inventory.json");

        var config: InstallInventory = Json.parse(installInventoryFile.readText());

        // TODO add everything in the lib directory to the CLASSPATH

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
                var javaExec = PythonShutil2.which("java");
                trace("creating symlink " + javaExec + " --> " + javaAppNameSymLink);
                PythonOs2.symlink(javaExec, javaAppNameSymLink);
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

        archiveOldLogs();

        var popenArgs = 
            if ( config.kind == "jvm" ) 
                resolveJvmLaunchArgs(cast config);
            else if ( config.kind == "args" ) 
                resolveStandardArgs(cast config);
            else 
                throw "unable to resolve config kind " + config.kind;

        // trace("" + popenArgs.args);

        var popen = new Popen(popenArgs.args, null, popenArgs.executable, null, Subprocess.PIPE, Subprocess.PIPE, null, false, false, popenArgs.cwd, popenArgs.env);

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

typedef ResolvedArgs = {
    var args: Array<String>;
    var env: python.Dict<String,String>;
    var cwd: String;
    var executable: String;
}


typedef LaunchConfig = {
    var kind: String;
}

typedef JvmLaunchConfig = {
    var config: AppInstallerConfig;
    var mainClass: String;
    var jvmArgs: Array<String>;
    var installDir: String;
    var args: Array<String>;
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
    var appDir: String;
    var libDir: String;
    var webappExplode: Bool;
}

