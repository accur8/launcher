package a8;



@:tink
class UserConfig {

    // @:lazy public static var sbtCredentials(default, null): StringMap<String> = {
    //     a8.PathOps.userHome()
    //         .entry(".sbt/credentials")
    //         .readProperties()
    //         ;
    // }


    @:lazy public static var versionsConfig(default, null): StringMap<String> = {
        a8.PathOps.userHome()
            .entry(".a8/versions/config.properties")
            .readProperties()
            ;
    }

    @:lazy public static var repoConfig(default, null): StringMap<String> = {
        a8.PathOps.userHome()
            .entry(".a8/repo.properties")
            .readProperties()
            ;
    }

    @:lazy public static var repo_url(default, null): String = {
        var v = repoConfig.get("repo_url");
        
        var u = repoConfig.get("repo_user");
        var p = repoConfig.get("repo_password");

        if ( v != null ) {
            var separator = "://";
            var split = v.split(separator);
            var url = split[0] + separator + u + ":" + p + "@" + split[1];
            url;
        } else {
            throw "no default_repo_url defined in ~/.a8/config.properties";
        }
    }


}