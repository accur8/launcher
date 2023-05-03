package a8.launcher;



import a8.launcher.Main;
import a8.PyOps;
import python.Bytearray;
import a8.Exec;
import haxe.ds.Option;

using a8.PathOps;

interface DependencyDownloader {
    public function name(): String;
    public function download(launcher: Launcher, jvmlauncher: JvmCliLaunchConfig, installInventoryFile: Path): Void;
}



class CoursierDependencyDownloader implements DependencyDownloader {
    
    public function new() {
    }

    public function name(): String {
        return "coursier";
    }

    public function download(launcher: Launcher, jvmlauncher: JvmCliLaunchConfig, installInventoryFile: Path): Void {

        var exec = new a8.Exec();

        // coursier launch -r https://deployer:Eb26fhnWFatdyAdeg84fAQ@accur8.jfrog.io/accur8/all a8:a8-versions_2.12:1.0.0-20180425_1229_master -M a8.versions.apps.Main
        // var user: String = UserConfig.sbtCredentials.get("user");
        // var password: String = UserConfig.sbtCredentials.get("password");

        var version = UserConfig.repoConfig.get("versions_version").toOption().getOrElse(Constants.a8VersionsVersion);

        var repoPrefix = "repo";
        if ( jvmlauncher.repo != null )
            repoPrefix = jvmlauncher.repo;

        var repoUrl = UserConfig.repo_url(repoPrefix);

        var args = exec.args = [PathOps.programPath().parent() + "/coursier", "launch", "--repository", repoUrl, 'io.accur8:a8-versions_2.13:${version}', "-M", "a8.versions.apps.Main", "--", "resolve", "--organization", jvmlauncher.organization, "--artifact", jvmlauncher.artifact, "--repo", repoPrefix];
        Sys.println("running -- " + args.join(" "));
        if ( launcher.config.explicitVersion != null ) {
            args.push("--version");
            args.push(launcher.config.explicitVersion);
        } else if ( jvmlauncher.branch != null ) {
            args.push("--branch");
            args.push(jvmlauncher.branch);
        } else if ( jvmlauncher.version != null ) {
            args.push("--version");
            args.push(jvmlauncher.version);
        }
        exec.execInline();
        Sys.println("completed running -- " + args.join(" "));

    }

}


class NixDependencyDownloader implements DependencyDownloader {

    public function new() {
    }


    public function name(): String {
        return "nix";
    }

    public function download(launcher: Launcher, jvmlauncher: JvmCliLaunchConfig, installInventoryFile: Path): Void {
        var workDir: Path = installInventoryFile.parent().subpath(installInventoryFile.basename() + "-work").realPath();
        var launcherDir = workDir.subpath("launcher");
        launcherDir.makeDirectories();

        var nixBuildDescription = fetchNixBuildDescription(launcher, jvmlauncher);

        var defaultDotNixPath = launcherDir.subpath("default.nix");
        defaultDotNixPath.writeText(nixBuildDescription.defaultDotNixContents);

        var javaLauncherTemplatePath = launcherDir.subpath("java-launcher-template");
        javaLauncherTemplatePath.writeText('#!/bin/bash\n\nexec _out_/bin/_name_j -cp _out_/lib/*:. _args_ "$@"\n');

        var exec = new a8.Exec();
        exec.args = ["/nix/var/nix/profiles/default/bin/nix-build", "--out-link", "build", "-E", "with import <nixpkgs> {}; (callPackage ./launcher {})"];
        exec.cwd = Some(workDir.toString());
        exec.execInline();

        var classath = [for (p in workDir.subpath("build/lib").entries()) p.realPathStr()];

        var inventory: InstallInventory = 
            {
                classpath: classath,
                appInstallerConfig: {
                    groupId: jvmlauncher.organization,
                    artifactId: jvmlauncher.artifact,
                    version: nixBuildDescription.version,
                    libDirKind: "nix",
                    webappExplode: jvmlauncher.webappExplode
                }
            };

        installInventoryFile.writeText(haxe.Json.stringify(inventory, null, "    "));

        var installInventoryFileNixDrv = PathOps.path(installInventoryFile.toString() + ".drv");
        var nixDrvPath = workDir.subpath("build").realPath();

        // create nix GC root
        var login = python.lib.Os.environ.get("USER");

        var gcRootName = '/nix/var/nix/gcroots/per-user/${login}/${jvmlauncher.organization}-${jvmlauncher.artifact}-${installInventoryFile.basename()}';

        // add gc root
        Logger.trace('resolvedVersion is ${nixBuildDescription.version}');

        Logger.trace('creating link from inventory file to nix derivation ${installInventoryFileNixDrv} --> ${nixDrvPath}');
        installInventoryFileNixDrv.deleteIfExists();
        PyOs2.symlink(nixDrvPath.toString(), installInventoryFileNixDrv.toString());

        Logger.trace('creating nix gc root ${gcRootName} --> ${installInventoryFileNixDrv}');
        PathOps.path(gcRootName).deleteIfExists();
        PyOs2.symlink(installInventoryFileNixDrv.toString(), gcRootName);

        // cleanup work directory
        workDir.deleteTree();

    }

    function fetchNixBuildDescription(launcher: Launcher, jvmlauncher: JvmCliLaunchConfig): {version: String, defaultDotNixContents: String} {

        var repoUrl = {
            var url = UserConfig.repo_url("repo");
            var p = PyUrllibParse.urlparse(url);
            var result = p.scheme + "://" + p.netloc;
            launcher.logTrace("repoApiUrl is " + result);
            result;
        }

        function fetchNixBuildDescriptionNew(): {version: String, defaultDotNixContents: String} {

            var requestBody: Dynamic = jvmlauncher;

            launcher.logTrace("nixBuildDescription -- " + haxe.Json.stringify(requestBody));

            var nixBuildDescriptionResponseStr = PyHttpAssist.httpPost("https://locus2.accur8.io/api/nixBuildDescription", requestBody);
            var nixBuildDescription: NixBuildDescription = haxe.Json.parse(nixBuildDescriptionResponseStr);

            var defaultDotNixContents =
                nixBuildDescription.files.filter(f -> f.filename == "default.nix").shift().contents;

            return {
                version: nixBuildDescription.resolvedVersion,
                defaultDotNixContents: defaultDotNixContents,
            };

        }

        function fetchNixBuildDescriptionLegacy(): {version: String, defaultDotNixContents: String} {

            var requestBody: Dynamic = jvmlauncher;

            launcher.logTrace("javaLauncherInstallerDotNix -- " + haxe.Json.stringify(requestBody));

            var defaultDotNixContents = PyHttpAssist.httpPost("https://locus2.accur8.io/api/javaLauncherInstallerDotNix", requestBody);

            return {
                version: "",
                defaultDotNixContents: defaultDotNixContents,
            };

        }

        try {
            return fetchNixBuildDescriptionNew();
        } catch (e) {
            Logger.trace("/api/nixBuildDescription failed will use legacy api");
            return fetchNixBuildDescriptionLegacy();
        }

    }

}

typedef NixArtifact = {
    var url: String;
    var sha256: String;
}

typedef DependencyTreeResponse = {
    var version: String;
    var artifacts: Array<ArtifactResponse>;
}

typedef ArtifactResponse = {
    var url: String;
    var checksums: Array<String>;
}

typedef NixBuildDescription = {
    var files: Array<FileContents>;
    var resolvedVersion: String;
    var resolutionResponse: ResolutionResponse;
}

typedef ResolutionResponse = {
    var request: Dynamic;
    var version: String;
    var repoUrl: String;
    var artifacts: Array<Artifact>;
}

typedef Artifact = {
    var url: String;
    var organization: String;
    var module: String;
    var version: String;
    var extension: String;
}

typedef FileContents = {
    var filename: String;
    var contents: String;
}

