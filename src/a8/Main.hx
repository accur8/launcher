package a8;


import sys.FileSystem;

using Lambda;
using a8.PathOps;
import haxe.Json;
import python.lib.subprocess.Popen;
import python.lib.Subprocess;
import python.lib.threading.Thread;
import python.lib.io.FileIO;
import python.Bytes;
import a8.parser.Position;
import a8.parser.Parser;

class Main {

    static function pipe(context: String, infile: FileIO): Thread {

        function impl() {
            var iter = new python.HaxeIterator<Bytes>(cast infile);
            for ( line in iter ) {
                python.Lib.print(context + " -- " + line.decode("utf-8"));
            }
        }

        var th = new Thread({target:impl});
        th.start();

        return th;

    }

    static public function main(): Void {

        if ( false )
            MacroPlay.run();

        var ep = PathOps.executablePath();
        var pp = PathOps.programPath();
        var configFile = ep.parent().entry(ep.file + ".json");

        trace("python.lib args:" + python.lib.Sys.argv);
        trace("python.lib executable:" + python.lib.Sys.executable);

        trace("args:" + Sys.args());
        trace("executablePath: " + ep);
        trace("executablePath Parent: " + ep.parent());
        trace("programPath: " + pp);
        trace("config: " + configFile);

        var p0 = PathOps.path("/Users/glen/code/glen/haxe-python/foo.py");
        var p1 = PathOps.path("foo.py");

        trace("-- strings 1 --");
        trace(p0.toString());
        trace(p1.toString());
        trace("-- strings 2 --");

        var config: LaunchConfig = Json.parse(configFile.readText());

        trace(config.args);

        // var popen = new Popen(config.args, null, null, null, Subprocess.PIPE, Subprocess.PIPE);

        // pipe("stdout", popen.stdout);
        // pipe("stderr", popen.stderr);

        // popen.wait();

        trace("program complete closing");


        var pos = new Position(0);

        var myParser = new MyParser();

        // trace(myParser.Root.fullParse("foo"));
        // trace(myParser.Root.fullParse("bar"));
        // trace(myParser.Root.fullParse("boom"));

        // trace(myParser.FooAndBar.fullParse("foo_bar_"));
        trace(myParser.FooOrBarSeq.fullParse("foo_bar_bar_foo_foo_bar_foo_bar_"));
        trace(myParser.FooOrBarSeq.fullParse("foo_bar_bar_foo_foo_bar_foo_bar_tim"));
        trace(myParser.FooOrBarSeq4.fullParse("foo_bar_bar_foo_foo_bar_foo_bar_"));
        trace(myParser.FooOrBarSeq4.fullParse("foo_bar_bar_"));

    }

}

@:tink 
class MyParser extends ParserBuilder {
    
    @:lazy var Foo: Parser<String> = str("foo_");

    @:lazy var Bar: Parser<String> = str("bar_");

    @:lazy var FooOrBar: Parser<String> = Foo | Bar;

    @:lazy var FooOrBarSeq: Parser<Array<String>> = FooOrBar.rep({min:1});

    @:lazy var FooOrBarSeq4: Parser<Array<String>> = FooOrBar.rep({min:4, max:4});

    // @:lazy var FooAndBar = (Foo & Bar).void();

    public function new() {
    }

}


typedef LaunchConfig = {
  var args: Array<String>;
}

/*

cwd - current working directory relative to this config file
mainClass - 
jvm args - 
auto restart - 



== general library ==
    
    * logging



== features ==

    * entry date and time as the header for every log file
        * stderr log is empty and on first bytes gets this header
    * gzip and archive log files
    * roll/archive large active log files
    * max size for entire archive folder
    * max size for this programs log files
    * warning/notification system




== possibly someday ==

    * semaphore to run a single instance



*/

