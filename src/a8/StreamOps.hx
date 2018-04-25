package a8;


import a8.Streams;
import python.lib.io.FileIO;
import python.lib.io.TextIOBase;
import python.lib.Io;

class StreamOps {
    
    public static function asInputStream(fileIO: FileIO): InputStream {
        return new FileIOInputStream(fileIO);        
    }

    public static function asOutputStream(io: TextIOBase): OutputStream {
        return new TextIOBaseOutputStream(io);
    }

    public static function fileOutputStream(filename: String): OutputStream {
        return asOutputStream(cast Io.open(filename,"wt"));
    }

}

class StreamOps2 {

    public static function asOutputStream(output: haxe.io.Output): OutputStream {
        return new OutputOutputStream(output);
    }

}

