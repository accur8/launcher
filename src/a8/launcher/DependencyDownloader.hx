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

        var requestBody: Dynamic = jvmlauncher;

        launcher.logTrace("javaLauncherInstallerDotNix -- " + haxe.Json.stringify(requestBody));

        var javaLauncherInstallerDotNixContent = PyHttpAssist.httpPost("https://locus.accur8.io/api/javaLauncherInstallerDotNix", requestBody);

        var workDir: Path = PathOps.path("launcher-work").realPath();
        var launcherDir = workDir.subpath("launcher");
        launcherDir.makeDirectories();

        var defaultDotNixPath = launcherDir.subpath("default.nix");
        defaultDotNixPath.writeText(javaLauncherInstallerDotNixContent);

        var javaLauncherTemplatePath = launcherDir.subpath("java-launcher-template");
        javaLauncherTemplatePath.writeText('#!/bin/bash\n\nexec _out_/bin/_name_j -cp _out_/lib/*:. _args_ "$@"\n');

        var exec = new a8.Exec();
        exec.args = ["/nix/var/nix/profiles/default/bin/nix-build", "--out-link", "build", "-E", "with import <nixpkgs> {}; (callPackage ./launcher {})"];
        exec.cwd = Some(workDir.toString());
        exec.execInline();

        var classath = [for (p in workDir.subpath("build/lib").entries()) p.realPathStr()];

        // cleanup work directory
        workDir.deleteTree();

        var inventory: InstallInventory = 
            {
                classpath: classath,
                appInstallerConfig: {
                    groupId: jvmlauncher.organization,
                    artifactId: jvmlauncher.artifact,
                    version: jvmlauncher.version,
                    libDirKind: "nix",
                    webappExplode: jvmlauncher.webappExplode
                }
            };

        installInventoryFile.writeText(haxe.Json.stringify(inventory));

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
