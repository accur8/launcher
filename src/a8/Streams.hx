package a8;



import python.Bytes;
import python.lib.io.FileIO;
import python.lib.io.IOBase;
import python.lib.Io;
import python.lib.io.TextIOBase;
import python.lib.threading.Thread;
import a8.Platform;

interface OutputStream {
    function write(s: String): Void;
    function flush(): Void;
    function close(): Void;
}


interface InputStream {
    function readLine(): String;
    function close(): Void;
}


@:tink
class FileIOInputStream implements InputStream {

    var delegate: FileIO = _;

    public function readLine(): String {
        var bytes: Bytes = cast delegate.readline();
        var line = bytes.decode();
        // trace("read line " + line);
        return 
            if ( line.endsWith("\n") ) {
                line.substr(0, line.length-1);
            } else {
                null;
            }
    }

    public function close(): Void {

    }

}


@:tink
class TextIOBaseOutputStream implements OutputStream {

    var delegate: TextIOBase = _;

    public function write(s: String): Void {
        delegate.write(s);
    }

    public function flush(): Void {
        delegate.flush();
    }

    public function close(): Void {
        delegate.close();
    }

}


@:tink
class FileIOOutputStream implements OutputStream {

    var delegate: FileIO = _;

    public function write(s: String): Void {
        delegate.write(new Bytes(s,"utrf-8"));
    }

    public function flush(): Void {
        delegate.flush();
    }

    public function close(): Void {
        delegate.close();
    }

}


@:tink
class TeeOutputStream implements OutputStream {

    var outputs: Array<OutputStream>;

    public function new(outputs: Array<OutputStream>) {
        this.outputs = outputs;
    }

    public function write(s: String): Void {
        outputs.iter(function (os) {
            os.write(s);
        });
    }

    public function flush(): Void {
        outputs.iter(function (os) {
            os.flush();
        });
    }

    public function close(): Void {
        outputs.iter(function (os) {
            os.close();
        });
    }

}


class Pipe {

    var input: InputStream;
    var output: OutputStream;

    var firstIO: OutputStream->Void;

    var byteCount: Int;

    public var replaceOutput: OutputStream -> OutputStream;

    public function new(input: InputStream, output: OutputStream, firstIO: OutputStream->Void) {
        this.input = input;
        this.output = output;
        this.firstIO = firstIO;
        this.byteCount = 0;
    }

    /**
     *  run the pipe in a separate thread
     */
    public function run(): Void {

        function impl() {
            var first = true;
            var cont = true ;
            while ( cont ) {
                var line = input.readLine();
                if ( replaceOutput != null ) {
                    output = replaceOutput(output);
                    first = true;
                }
                if ( line == null ) {
                    cont = false;
                } else {
                    if ( first ) {
                        firstIO(output);
                        first = false;
                    }
                    output.write(line);
                    output.write("\n");
                    output.flush();
                    byteCount += (line.length + 1);
                }
            }
            output.close();
        }

        a8.PlatformOps.instance.spawn("pipe", impl);

    }

}




