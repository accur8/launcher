package a8;



import python.Bytes;
import python.lib.io.FileIO;
import python.lib.io.IOBase;
import python.lib.Io;
import python.lib.io.TextIOBase;
import a8.ValueClass;
import python.lib.threading.Thread;


interface OutputStream {
    function write(s: String): Void;
    function flush(): Void;
    function close(): Void;
}


interface InputStream {
    function readLine(): String;
    function close(): Void;
}


class FileIOInputStream implements InputStream implements ValueClass {

    var delegate: FileIO;

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


class TextIOBaseOutputStream implements OutputStream implements ValueClass {

    var delegate: TextIOBase;

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


class FileIOOutputStream implements OutputStream implements ValueClass {

    var delegate: FileIO;

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


class TeeOutputStream implements ValueClass implements OutputStream {

    var outputs: Array<OutputStream>;

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

    public function new(input: InputStream, output: OutputStream, firstIO: OutputStream->Void) {
        this.input = input;
        this.output = output;
        this.firstIO = firstIO;
        this.byteCount = 0;
    }

    public function run(): Thread {

        function impl() {
            var first = true;
            var cont = true ;
            while ( cont ) {
                var line = input.readLine();
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

        var th = new Thread({target:impl});
        th.start();

        return th;

    }

}




