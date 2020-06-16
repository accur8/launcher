package a8;



@:tink
class UserConfig {

    // @:lazy public static var sbtCredentials(default, null): StringMap<String> = {
    //     a8.PathOps.userHome()
    //         .entry(".sbt/credentials")
    //         .readProperties()
    //         ;
    // }

    @:lazy public static var repoConfig(default, null): StringMap<String> = {
        a8.PathOps.userHome()
            .entry(".a8/repo.properties")
            .readProperties()
            ;
    }

    static function getRepoProp(name: String): String {
        var v = repoConfig.get(name);
        if ( v == null ) {
            throw "no " + name + " defined in ~/.a8/repo.properties";
        }
        return v;
    }

    @:lazy public static var repo_url(default, null): String = {
        var v = getRepoProp("repo_url");
        
        var u = getRepoProp("repo_user");
        var p = getRepoProp("repo_password");

        var separator = "://";
        var split = v.split(separator);
        var url = split[0] + separator + u + ":" + p + "@" + split[1];
        url;
    }


}