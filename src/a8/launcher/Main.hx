package a8.launcher;


import sys.FileSystem;
import a8.Streams;

import haxe.Json;
import a8.PyOps;
import python.Lib;
import a8.launcher.CommandLineProcessor;

@:tink
class Main {

    static function loadConfig(): LaunchConfig {

        var execPath = PathOps.executablePath();
        var appName = execPath.file;

        var configExtensions = [".json", ".launcher.json"];

        var possibleConfigFiles = 
            execPath
                .symlinkChain()
                .flatMap([l] => configExtensions.map([e] => l.parent().entry(l.name() + e)))
                .array()
                ;

        // trace(possibleConfigFiles);

        var configFile = 
            possibleConfigFiles
                .find([f]=>f.exists())
                ;

        var config: LaunchConfig = Json.parse(configFile.readText());

        if ( config.quiet == null ) {
            config.quiet = false;
        }
        if ( config.logRollers == null ) {
            config.logRollers = [];
        }
        if ( config.logFiles == null ) {
            config.logFiles = true;
        }
        if ( config.kind == "jvm_cli") {
            var jvmLaunchConfig: JvmLaunchConfig = cast config;
            config.installDir = null;
            config.logFiles = false;
            config.logRollers = [];
        }
        if ( config.kind == "jvm" || config.kind == "jvm_cli") {
            var jvmLaunchConfig: JvmLaunchConfig = cast config;
            if ( jvmLaunchConfig.jvmArgs == null ) 
                jvmLaunchConfig.jvmArgs = [];
            if ( jvmLaunchConfig.args == null ) 
                jvmLaunchConfig.args = [];

        }

        return config;

    }

    public static function main(): Void {

        try {

            var execPath = PathOps.executablePath();

            var appName = execPath.file;

            var initialConfig = loadConfig();

            var args = PySys.argv.copy();
            initialConfig.rawCommandLineArgs = args;

            var clp = new CommandLineProcessor();
            var config = clp.apply(initialConfig);

            Logger.traceEnabled = !config.quiet;

            var launcher = 
                new Launcher(
                    config,
                    appName,
                    args
                );

            launcher.runAndWait();
        } catch (e: Dynamic) {
            var stack = haxe.CallStack.exceptionStack();
            Logger.warn("" + e + "\n" + stack.asString("    "));
            Sys.exit(1);
        }

        Sys.exit(0);

    }

}


typedef LaunchConfig = {
    
    var kind: String;

    @:optional var quiet: Bool;
    @:optional var installDir: String;
    @:optional var logsDir: String;
    @:optional var logRollers: Array<Dynamic>;
    @:optional var logFiles: Bool;
    @:optional var resolveOnly: Bool;

    /* all items below are not loaded from the json */

    /* ability to explicitly set the version that will run */
    @:optional var explicitVersion: Option<String>;

    /* the command line args with the launcher args are removed */
    @:optional var resolvedCommandLineArgs: Array<String>;

    /* the command line args before the launcher args are removed */
    @:optional var rawCommandLineArgs: Array<String>;

}

/*


    when running standalone commands
        no log files
        do not set current working directory
        installDir not required
        kind = jvm_cli
        webappExplode is ignored


    when running app servers
        log files
        set current working directory to be the install Directory
        installDir required
        kind = jvm


*/


typedef JvmLaunchConfig = {
    // var kind: String;
    var mainClass: String;
    @:optional var jvmArgs: Array<String>;
    @:optional var args: Array<String>;
}

typedef JvmCliLaunchConfig = {
    // var kind: String;
    var organization: String;
    var artifact: String;
    @:optional var version: String;
    @:optional var branch: String;
    var mainClass: String;
    @:optional var jvmArgs: Array<String>;
    @:optional var args: Array<String>;
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
    @:optional var installDir: String;
    @:optional var libDirKind: String;
    @:optional var webappExplode: Bool;
}

