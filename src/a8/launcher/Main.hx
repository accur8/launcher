package a8.launcher;


import sys.FileSystem;
import a8.Streams;

import haxe.Json;
import a8.PyOps;
import python.Lib;
import a8.launcher.CommandLineProcessor;
import Sys;
import haxe.io.Path;

@:tink
class Main {

    static function loadConfig(commandLineParms: CommandLineParms): LaunchConfig {

        var execPath = PathOps.executablePath();
        var appName = execPath.file;

        var configExtensions = [".json", ".launcher.json"];

        var configFile: Path = 
            if( commandLineParms.launcherJson != null ) {
                PathOps.path(commandLineParms.launcherJson);
            } else {
                var possibleConfigFiles = 
                    execPath
                        .symlinkChain()
                        .flatMap([l] => configExtensions.map([e] => l.parent().entry(l.name() + e)))
                        .array()
                        ;

                possibleConfigFiles
                    .find([f]=>f.exists())
                    ;
            }

        var config: LaunchConfig = Json.parse(configFile.readText());

        config.commandLineParms = commandLineParms;

        if ( commandLineParms.quiet != null ) {
            config.quiet = commandLineParms.quiet;
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

        if ( commandLineParms.explicitVersion != null ) {
            config.explicitVersion = commandLineParms.explicitVersion;
        }

        return config;

    }

    // TODO when we get to the point of documenting how to configure an app a starting point is the 'Config Json Usage:' section in:
    // https://docs.google.com/document/d/1u190L69DamowN1scP-0vzizdYzrr8lbc8ApS5dN0CoM/edit#
    public static function helpString(): String {
        return '
Accur8 Launcher Tool

    The launchers job is to make sure the app is installed in the local cache and run the app it is configured to run.  

    It will usually be installed (using Accur8 Recipes ie: a8-recipe install a8-scripts) at ~/tools-a8/packages/a8-scripts/a8-launcher.py

Configuration:
    An app being run by the a8-launcher.py (or a copy/symbolic link of the launcher like a8-zoo) is configured by a .json file which will be alongside the command. 
    The base filename of the command needs to be the same as the json file. 
    So if you run the ‘a8-zoo’ launch command it will look for a ‘a8-zoo.json’ sitting alongside the a8-zoo command. 
    An example of a8-zoo.json will look like:
        {
            "kind": "jvm_cli",
            "mainClass": "a8.zoolander.Main",
            "organization": "a8",
            "artifact": "a8-zoolander_2.12",
            "branch": "master",
            "repo": "maven"
        }

Usage requirements:

    Python 3.4+ (currently Python versions 3.7 does not work)


Usage:

    --l-launcherJson <launcher.json>
        override the default launcher json lookup with a specific launcher json file to use

    --l-version <version> [<args>]
        Runs the app with the specific version requested.

    --l-verbose
        turn on more verbose logging

    --l-resolveOnly
        Does not run the app.
        Sets up the inventory file(s) in a8VersionCache (~/a8/versions/cache) which contain app installer config and classpaths to jars.
    
    --l-help
        Does not run the app.
        Shows this help text.

    [<args>]
        Run the app passing through whatever arguments are passed in
        
';
    }

    public static function main(): Void {

        var exitCode = 0;

        try {

            var commandLineParms = CommandLineProcessor.parse();

            var execPath = PathOps.executablePath();

            var appName = execPath.file;

            var config = loadConfig(commandLineParms);

            var args = PySys.argv.copy();

            Logger.traceEnabled = !config.quiet;

            if ( commandLineParms.showHelp ) {
                Sys.print(helpString());
            } else {
                var launcher = 
                    new Launcher(
                        config,
                        appName,
                        args
                    );
                exitCode = launcher.runAndWait();
            }
            
        } catch (e: Dynamic) {
            var stack = haxe.CallStack.exceptionStack();
            Logger.warn("" + e + "\n" + stack.asString("    "));
            Sys.exit(1);
        }

        Sys.exit(exitCode);

    }

}


typedef LaunchConfig = {
    
    var kind: String;

    var quiet: Bool;
    @:optional var installDir: String;
    @:optional var logsDir: String;
    @:optional var logRollers: Array<Dynamic>;
    @:optional var logFiles: Bool;

    /* all items below are not loaded from the json */

    /* ability to explicitly set the version that will run */
    @:optional var explicitVersion: String;

    var commandLineParms: CommandLineParms;

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


typedef CommandLineParms = {
    var programName: String;

    /* the command line args with the launcher args are removed */
    var resolvedCommandLineArgs: Array<String>;

    /* the command line args before the launcher args are removed */
    var rawCommandLineArgs: Array<String>;

    var resolveOnly: Bool;

    @:optional var quiet: Bool;
    @:optional var explicitVersion: String;
    @:optional var launcherJson: String;    
    @:optional var showHelp: Bool;

}

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
    @:optional var repo: String;
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

