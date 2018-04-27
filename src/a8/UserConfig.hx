package a8;



@:tink
class UserConfig {

    @:lazy public static var sbtCredentials(default, null): StringMap<String> = {
        a8.PathOps.userHome()
            .entry(".sbt/credentials")
            .readProperties()
            ;
    }


    @:lazy public static var versions(default, null): StringMap<String> = {
        a8.PathOps.userHome()
            .entry(".a8/versions/config.properties")
            .readProperties()
            ;
    }


}