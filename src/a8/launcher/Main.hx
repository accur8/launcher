package a8.launcher;


import sys.FileSystem;
import a8.Streams;

using Lambda;

import haxe.Json;
import a8.PyOps;
using a8.PathOps;

class Main {

    static function loadConfig(): LaunchConfig {

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
        if ( config.logFiles == null ) {
            config.logFiles = true;
        }
        if ( config.kind == "jvm_cli") {
            var jvmLaunchConfig: JvmLaunchConfig = cast config;
            jvmLaunchConfig.webappExplode = false;
            jvmLaunchConfig.libDirKind = "repo";
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

        trace("" + Sys.args());
        trace("started");

        var execPath = PathOps.executablePath();

        var appName = execPath.file;

        var config = loadConfig();

        var launcher = 
            new Launcher(
                config,
                appName
            );

        launcher.runAndWait();

    }

}


typedef LaunchConfig = {
    var kind: String;
    @:optional var quiet: Bool;
    @:optional var installDir: String;
    @:optional var logsDir: String;
    @:optional var logRollers: Array<Dynamic>;
    @:optional var logFiles: Bool;
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
    var kind: String;
    var mainClass: String;
    @:optional var jvmArgs: Array<String>;
    @:optional var args: Array<String>;
    @:optional var webappExplode: Bool;
    @:optional var libDirKind: String;
}

typedef JvmCliLaunchConfig = {
    var kind: String;
    var organization: String;
    var artifact: String;
    @:optional var version: String;
    @:optional var branch: String;
    var mainClass: String;
    @:optional var jvmArgs: Array<String>;
    @:optional var args: Array<String>;
    @:optional var webappExplode: Bool;
    @:optional var libDirKind: String;
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

