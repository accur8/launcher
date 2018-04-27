package a8.launcher;


import a8.launcher.Main;

@:tink
class CommandLineProcessor {

    @:lazy var argDefs: Array<ProgramArg> = [
        { 
            name: "--l-version", 
            parmCount: 1,
            apply: function(config: LaunchConfig, args: Option<String>) {
                config.explicitVersion = args;
            }
        },{ 
            name: "--l-verbose", 
            parmCount: 0,
            apply: function(config: LaunchConfig, args: Option<String>) {
                config.quiet = args.isEmpty();
            }
        },{ 
            name: "--l-resolveOnly", 
            parmCount: 0,
            apply: function(config: LaunchConfig, args: Option<String>) {
                config.resolveOnly = args.nonEmpty();
            }
        }
    ];

    public function new() {
    }

    public function apply(initialConfig: LaunchConfig): LaunchConfig {
        var config = Reflect.copy(initialConfig);

        var newArgs = [];
        config.resolvedCommandLineArgs = newArgs;
        var temp = initialConfig.rawCommandLineArgs.copy();

        // drop the first arg since it is the program name
        temp.reverse();
        temp.pop();

        while ( temp.length > 0 ) {
            var a = temp.pop();
            var argDef: ProgramArg = argDefs.find([ad] => ad.name == a);
            if ( argDef == null ) {
                if ( a.startsWith("--l-") ) {
                    throw new Exception('don\'t know how to handle arg -- ${a}');
                }
                newArgs.push(a);
            } else {
                var parms = 
                    if ( argDef.parmCount == 0 ) Some(argDef.name);
                    else if ( argDef.parmCount == 1 ) Some(temp.pop());
                    else throw new Exception("can only handle parmCount of 0 or 1");
                argDef.apply(config, parms);
                argDef.processed = true;
            }
        }

        // process missing args
        argDefs.iter(function(ad) {
            if ( ad.processed ) {
                // already process noop
            } else {
                ad.apply(config, None);
            }
        });

        return config;
    }

}


typedef ProgramArg = {
    var name: String;
    var parmCount: Int;
    var apply: LaunchConfig -> Option<String> -> Void;
    @:optional var processed: Bool;
}
