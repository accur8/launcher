package a8.launcher;


import a8.Streams;
import python.lib.io.TextIOBase;

using a8.PathOps;
using a8.StreamOps;
using a8.OptionOps;

@:tink
class PipedStream {

    var launcher: Launcher = _;
    var processInput: InputStream = _;
    var stdxxx: TextIOBase = _;
    var fileExtension: String = _;
    var firstIO: OutputStream->Void = _;
    var pipeToLogFiles: Bool = _;
    var initialTimestampStr: String = _;

    var pipe: Pipe;

    var outputFile: Option<PipedStreamOutputFile> = None;

    var started = false;

    public function start() {
        if ( !started ) {
            this.started = true;
            if ( this.pipeToLogFiles ) {
                var of = newOutputFile(initialTimestampStr);
                this.outputFile = Some(of);
                this.pipe = new Pipe(processInput, of.teedOut, firstIO);
                this.pipe.run();
            } else {
                this.outputFile = None;
                this.pipe = new Pipe(processInput, stdxxx.asOutputStream(), firstIO);
                this.pipe.run();
            }
        }
    }

    function newOutputFile(timesatmpStr: String): PipedStreamOutputFile {
        var fileOutputPath = timestampedOutputFile(timesatmpStr);
        var fileOut = StreamOps.fileOutputStream(fileOutputPath.realPathStr());
        var teeOut = new TeeOutputStream([fileOut, stdxxx.asOutputStream()]);
        return {
            path: fileOutputPath,
            outputStream: fileOut,
            teedOut: teeOut,
        }
    }

    function timestampedOutputFile(timestampStr: String): Path {
        return launcher.logsDir.entry(launcher.appName + "." + timestampStr + "." + fileExtension);
    }

    public function log(msg: String) {
        switch outputFile {
            case Some(of):
                try {
                    of.teedOut.write(msg);
                    of.teedOut.write("\n");
                } catch(e: Dynamic) {
                    trace("error logging - " + e);
                }
            default:
        } 
    }

    public function rollover(timestampStr: String) {
        switch outputFile {
            case Some(existingOutputFile):
                // a role would be done as follows
                //    1) get the pipedStream using a new file output
                var newFileOutputPath = timestampedOutputFile(timestampStr);
                var newfileOut = newFileOutputPath.outputStream();
                this.pipe.replaceOutput = [oldOut] => {
                    oldOut.close();
                    newfileOut;
                }

                //    2) move the old file to archives and gzip them
                var oldFileoutputPath = existingOutputFile.path;
                existingOutputFile.path = newFileOutputPath;
                existingOutputFile.outputStream = newfileOut;
                launcher.archiveLogFiles([oldFileoutputPath]);

                //    4) trigger any kind of disk space based log rollers
            case None: 
                throw "this should not happen since rollover should never get called when we don't have a Some for outputFile: Option<PipedStreamOutputFile>";
        }

    }

    public function close() {
        this.outputFile.iter([f] => f.teedOut.close());
    }

}


typedef PipedStreamOutputFile = {
    var path: Path;
    var outputStream: OutputStream;
    var teedOut: TeeOutputStream;
}
