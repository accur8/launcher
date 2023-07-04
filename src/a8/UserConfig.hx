package a8;



import haxe.Http;
import Sys;

@:tink
class UserConfig {

    // @:lazy public static var sbtCredentials(default, null): StringMap<String> = {
    //     a8.PathOps.userHome()
    //         .entry(".sbt/credentials")
    //         .readProperties()
    //         ;
    // }

    static var _repoConfig: StringMap<String>;

    static function loadRepoConfig(): Map<String, String> {
        var defaults:Map<String, String> = 
            [
                "repo_url" => "https://locus.accur8.net/repos/all",
                "maven_url" => "https://repo.maven.apache.org/maven2/"
            ];
        var userProps =
            a8.PathOps.userHome()
                .entry(".a8/repo.properties")
                .readProperties()
                ;
        var etcProps = 
            a8.PathOps.userHome()
                .entry("/etc/a8-repo.properties")
                .readProperties()
                ;
        var m1 = HaxeOps.mapMerge(defaults, etcProps);
        var m2 = HaxeOps.mapMerge(m1, userProps);
        // trace("boom");
        // trace(m2);
        return m2;
    }

    public static function getRepoConfig(): StringMap<String> {
        if ( _repoConfig == null ) {
            _repoConfig = loadRepoConfig();
        }
        return _repoConfig;
    }

    static function getRepoProp(repoPrefix: String, suffix: String): String {
        var name = repoPrefix + "_" + suffix;
        var v = getRepoConfig().get(name);
        if ( v == null ) {
            throw "no " + name + " defined in ~/.a8/repo.properties";
        }
        return v;
    }

    static function hasRepoProp(repoPrefix: String, suffix: String): Bool {
        var name = repoPrefix + "_" + suffix;
        var v = getRepoConfig().get(name);
        return v != null;
    }

    public static function repo_url(repoPrefix: String): String {
        if ( hasRepoProp(repoPrefix, "url") ) {

            var url = getRepoProp(repoPrefix, "url");
            
            if ( hasRepoProp(repoPrefix, "user") && hasRepoProp(repoPrefix, "password") ) {
                var u = getRepoProp(repoPrefix, "user");
                var p = getRepoProp(repoPrefix, "password");

                var separator = "://";
                var split = url.split(separator);
                url = split[0] + separator + u + ":" + p + "@" + split[1];
            }

            return url;
        } else if ( repoPrefix == "maven" ) {
            return "https://repo.maven.apache.org/maven2/";
        } else {
            throw "unable to find repo " + repoPrefix;
        }
    }


    public static function versionsVersion(repoPrefix: String): String {
        var version = getRepoConfig().get("versions_version");
        if ( version == null ) 
            version = versionsVersionFromRepo(repoPrefix);

        return version;
    }

    static function versionsVersionFromRepo(repoPrefix: String): String {
        var v = getRepoProp(repoPrefix, "url");
        var url = v.substring(0, v.indexOf("/", v.indexOf("://")+1)) + "/versionsVersion";
        return Http.requestUrl(url);
    }

}