package a8.launcher;


import a8.launcher.DependencyDownloader;
import a8.launcher.Main;
import a8.launcher.LogRoller;
import a8.launcher.PipedStream;
import a8.PyOps;
import a8.Streams;
import a8.UserConfig;
import haxe.Json;
import python.lib.subprocess.Popen;
import python.lib.Subprocess;
import python.Lib.PySys;
import haxe.ds.Option;
import Sys;
import a8.Constants;

@:tink
class Launcher {

    public var config: LaunchConfig = _;
    public var appName: String = _;

    var initialArgs: Array<String> = _;


    @:lazy var a8VersionsCache: Path = initDirectory(".a8/versions/cache", null, a8.PathOps.userHome());


    @:lazy var installDir: Path = initDirectory(config.installDir, null, a8.PathOps.path(python.lib.Os.getcwd()));
    @:lazy var logsDir: Path = initDirectory(config.logsDir, "logs", installDir);
    @:lazy var logArchivesDir: Path = initDirectory("archives", null, logsDir, this.config.logFiles);

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

    public function logTrace(msg: String, ?posInfo: haxe.PosInfos): Void {
        if ( !config.quiet ) {
            if ( pipedStdout != null ) {
                pipedStdout.log("TRACE - " + msg);
            } else {
                Logger.trace(msg, posInfo);
            }
        }
    }
    
    function logWarn(msg: String, ?posInfo: haxe.PosInfos): Void {
        if ( pipedStderr != null ) {
            pipedStderr.log("WARN - " + msg);
        } else {
            Logger.warn(msg, posInfo);
        }
    }

    function resolveAutoDependencyDownloaderName(): String {
        if ( PathOps.path("/nix/var/nix/profiles/default/bin/nix").exists() ) {
            return "nix";
        } else {
            return "coursier";
        }
    }

    function resolveDependencyDownloader(dependencyDownloaderName: String): DependencyDownloader {
        if ( dependencyDownloaderName == null ) {
            dependencyDownloaderName = "auto";
        }
        dependencyDownloaderName = dependencyDownloaderName.toLowerCase();

        if ( dependencyDownloaderName == "auto" ) {
            dependencyDownloaderName = resolveAutoDependencyDownloaderName();
            logTrace("resolving auto dependencyDownloader to " + dependencyDownloaderName);
        }
        
        var dependencyDownloader: DependencyDownloader;
        if ( dependencyDownloaderName == "coursier" ) {
            dependencyDownloader = new CoursierDependencyDownloader();
        } else if ( dependencyDownloaderName == "nix" ) {
            dependencyDownloader = new NixDependencyDownloader();
        } else {
            throw "unable to resolve DependencyDownloader named " + dependencyDownloaderName;
        }

        return dependencyDownloader;
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
                    target.deleteFile();
                    f.moveTo(target);
                    target;
                });

        logTrace("archiving log files -- " + archivedFiles);

        function gzipFiles() {
            archivedFiles.iter(function(f) {
                Subprocess.call(["gzip", "-f", f.realPathStr()]);
            });
        }

        PyOps.spawn(gzipFiles);

    }

    function resolveStandardArgs(stdlauncher: ArgsLaunchConfig): ResolvedLaunch {
        var launchConfig: LaunchConfig = cast stdlauncher;
        return {
            kind: "popen",
            args: stdlauncher.args,
            env: null,
            cwd: null,
            executable: null,
        };
    }

    function resolveJvmCliLaunchArgs(jvmlauncher: JvmCliLaunchConfig): ResolvedLaunch {
        var versionFile = 
            if ( this.config.explicitVersion != null ) {
                this.config.explicitVersion + ".json";
            } else if ( jvmlauncher.branch != null ) {
                "latest_" + jvmlauncher.branch + ".json";
            } else if ( jvmlauncher.version != null ) {
                jvmlauncher.version + ".json";
            } else {
                throw new Exception("must provide a config with branch or version");
            }
        var inventoryFile = a8VersionsCache.entry(jvmlauncher.organization + "/" + jvmlauncher.artifact + "/" + versionFile);
        logTrace("using inventory file - " + inventoryFile.toString());
        if ( !inventoryFile.exists() || this.config.commandLineParms.resolveOnly ) {
            var dependencyDownloader: DependencyDownloader = resolveDependencyDownloader(jvmlauncher.dependencyDownloader);    
            logTrace("using {dependencyDownloader.name()} dependency downloader");
            dependencyDownloader.download(this, jvmlauncher, inventoryFile);
        }
        var la = resolveJvmLaunchArgs(jvmlauncher, inventoryFile, false);

        la.kind = "exec";
        la.cwd = null;

        return la;

    }

    function resolveJvmLaunchArgs(jvmlauncher: JvmLaunchConfig, installInventoryFile: Path, createAppNameSymlink: Bool): ResolvedLaunch {

        if ( !installInventoryFile.exists() ) {
            throw new Exception("inventory file does not exist " + installInventoryFile.toString());
        }

        var launchConfig: LaunchConfig = cast jvmlauncher;

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

        if ( createAppNameSymlink ) {
            var symlinkName = "j_" + appName;
            var symlinkParent = installDir;
            var javaAppNameSymLink = symlinkParent.realPathStr() + "/" + symlinkName;
            var javaAppNameSymLinkPath = PathOps.path(javaAppNameSymLink);
            var cmd = 
                if ( !javaAppNameSymLinkPath.isFile() ) {
                    var javaExec = PyShutil2.which("java");
                    logTrace("creating symlink " + javaExec + " --> " + javaAppNameSymLink);
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
        } else {
            args.push("java");
        }

        args.push("-DappName=" + appName);

        if ( launcherD.jvmArgs != null ) 
            jvmlauncher.jvmArgs.iter(function(jvmArg) {
                args.push(jvmArg);
            });

        // logTrace(classpath);

        args.push(jvmlauncher.mainClass);

        if ( launcherD.args != null ) 
            jvmlauncher.args.iter(function(arg) {
                args.push(arg);
            });

        this.config.commandLineParms.resolvedCommandLineArgs.iter(function(arg) {
            args.push(arg);
        });

        var env = python.lib.Os.environ;

        var newEnv = env.copy();

        // logTrace('set -x CLASSPATH "' + classpath + '"');

        newEnv.set("CLASSPATH", classpath);
        newEnv.set("LAUNCHER_INSTALL_DIR", installDir.realPathStr());
        newEnv.set("LAUNCHER_WORKING_DIR", python.lib.Os.getcwd());
        newEnv.set("LAUNCHER_EXEC_PATH", PathOps.executablePath().realPathStr());

        return {
            kind: "popen",
            args: args,
            env: newEnv,
            cwd: installDir.realPathStr(),
            executable: args[0],
        };

    }


    public function runAndWait(): Int {

        logTrace("installDir = " + installDir);
        logTrace("logsDir = " + logsDir);
        logTrace("logArchivesDir = " + logArchivesDir);

        var resolvedLaunch: ResolvedLaunch = 
            if ( config.kind == "jvm" ) {
                var installInventoryFile = installDir.entry("install-inventory.json");
                resolveJvmLaunchArgs(cast config, installInventoryFile, true);
            } else if ( config.kind == "jvm_cli" ) {
                resolveJvmCliLaunchArgs(cast config);
            } else if ( config.kind == "args" )
                resolveStandardArgs(cast config);
            else 
                throw new Exception("unable to resolve config kind " + config.kind);

        if ( this.config.commandLineParms.resolveOnly ) {
            return 0;
        } else {

            if ( config.logFiles )
                archiveOldLogs();


            switch resolvedLaunch.kind {
                case "exec": 
                    // we use exec so this replaces the existing process with the exec'ed process
                    // so this program effecitvely exits when we call exec here
                    if ( resolvedLaunch.cwd != null ) 
                        python.lib.Os.chdir(resolvedLaunch.cwd);
                    PyOs2.execvpe(resolvedLaunch.executable, resolvedLaunch.args, resolvedLaunch.env);

                    throw new Exception("this never happens");

                case "popen":
                    logTrace("running -- " + resolvedLaunch.args);

                    var popen = new Popen(resolvedLaunch.args, null, resolvedLaunch.executable, null, Subprocess.PIPE, Subprocess.PIPE, null, false, false, resolvedLaunch.cwd, resolvedLaunch.env);

                    function firstIO(out: OutputStream): Void {
                        out.write("first output at " + PathOps.timestampStr() + "\n");
                    }

                    var timestampStr = PathOps.timestampStr();

                    logTrace("setting up pipes");
                    this.pipedStdout = new PipedStream(this, popen.stdout.asInputStream(), PySys.stdout, "details", firstIO, config.logFiles, timestampStr);
                    this.pipedStderr = new PipedStream(this, popen.stderr.asInputStream(), PySys.stderr, "errors", firstIO, config.logFiles, timestampStr);

                    this.pipedStdout.start();
                    this.pipedStderr.start();

                    // logDetail("pipes setup");

                    logTrace("initializeLogRollers");
                    initializeLogRollers();
                    logTrace("initializeLogRollers complete");

                    // logDetail("waiting for process to complete");
                    popen.wait();
                    // logDetail("process completed with exit code " + popen.returncode);

                    this.pipedStdout.close();
                    this.pipedStdout.close();

                    return popen.returncode;

                default:
                    throw new Exception("don't know how to handle ResolvedLaunch.kind = ${resolvedLaunch.kind}");
            }
        }
    }


    function initializeLogRollers() {
        this.logRollers = 
            config
                .logRollers
                .map([lr] => LogRollerOps.fromConfig(lr, this));
        this.logRollers.iter([i]=>i.init());
    }

}


typedef ResolvedLaunch = {
    var kind: String;   //  popen | exec
    var args: Array<String>;
    var env: python.Dict<String,String>;
    var cwd: String;
    var executable: String;
}

