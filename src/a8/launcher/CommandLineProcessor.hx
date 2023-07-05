package a8.launcher;


import a8.launcher.Main;
import python.Lib;

@:tink
class CommandLineProcessor {

    static function commandLineArgDefs(): Array<ProgramArg> {
        return [
            { 
                name: "--l-version", 
                parmCount: 1,
                apply: function(config: CommandLineParms, args: Option<String>) {
                    config.explicitVersion = args.orNull();
                },
                processed: false
            },{ 
                name: "--l-verbose", 
                parmCount: 0,
                apply: function(config: CommandLineParms, args: Option<String>) {
                    config.quiet = !args.nonEmpty();
                },
                processed: false
            },{ 
                name: "--l-launcherJson", 
                parmCount: 1,
                apply: function(config: CommandLineParms, args: Option<String>) {
                    config.launcherJson = args.orNull();
                },
                processed: false
            },{ 
                name: "--l-resolveOnly", 
                parmCount: 0,
                apply: function(config: CommandLineParms, args: Option<String>) {
                    config.resolveOnly = args.nonEmpty();
                },
                processed: false
            },{ 
                name: "--l-showVersion", 
                parmCount: 0,
                apply: function(config: CommandLineParms, args: Option<String>) {
                    config.showVersion = args.nonEmpty();
                },
                processed: false
            },{ 
                name: "--l-help", 
                parmCount: 0,
                apply: function(config: CommandLineParms, args: Option<String>) {
                    config.showHelp = args.nonEmpty();
                },
                processed: false
            }    
        ];
    }

    public static function parse(): CommandLineParms {

        var tempArgs = PySys.argv.copy();
        tempArgs.reverse();

        var newArgs = [];
        var config: CommandLineParms = {
            programName: tempArgs.pop(),
            rawCommandLineArgs: PySys.argv.copy(),
            resolvedCommandLineArgs: newArgs,
            resolveOnly: false,
        };

        var argDefs = commandLineArgDefs();

        while ( tempArgs.length > 0 ) {
            var a = tempArgs.pop();
            var argDef: ProgramArg = argDefs.find([ad] => ad.name == a);
            if ( argDef == null ) {
                if ( a.startsWith("--l-") ) {
                    throw new Exception('don\'t know how to handle arg -- ${a}');
                }
                newArgs.push(a);
            } else {
                var parms = 
                    if ( argDef.parmCount == 0 ) Some(argDef.name);
                    else if ( argDef.parmCount == 1 ) Some(tempArgs.pop());
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
    var apply: CommandLineParms -> Option<String> -> Void;
    @:optional var processed: Bool;
}
