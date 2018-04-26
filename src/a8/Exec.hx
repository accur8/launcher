package a8;



import python.lib.Subprocess;
import a8.Streams;



@:tink
class Exec {

    public var args: Array<String> = [];
    public var cwd: Option<String> = None;
    public var env: Option<Map<String,String>> = None;
    public var failOnNonZeroExitCode: Bool = true;
    public var executable: Option<String> = None;

    public function new() {
    }

    public function asCommandLine(): String {
        return args.join(" ");
    }

    /**
      *  Will run the process waiting til completion piping using the current processes
      *. stdin, stdout and stderr 
      */
    public function execInline(): Int {
        // trace("exec " + args);
        var exitCode = 
            python.lib.Subprocess.call(
                args,
                {
                    cwd: cwd.getOrElse(null)
                }
            );
        if ( exitCode != 0 && failOnNonZeroExitCode ) {
            throw 'non-zero exit code of ${exitCode} while executing -- ${asCommandLine()}';
        }
        return exitCode;
    }

    /**
      *  Will run the process waiting til completion capturing stdout and stderr to separate strings
      */
    public function execCapture(): ExecCaptureResult {

        var popen = 
            new python.lib.subprocess.Popen(
                args, 
                null, 
                executable.getOrElse(args[0]), 
                null, 
                Subprocess.PIPE, 
                Subprocess.PIPE, 
                null, 
                false, 
                false, 
                cwd.getOrElse(null), 
                env.map([e]=>e.toDict()).getOrElse(null)
            );

        function firstIO(out: OutputStream): Void {
        }

        var timestampStr = PathOps.timestampStr();

        var stdoutCapture = new haxe.io.BytesOutput();
        var stderrCapture  = new haxe.io.BytesOutput();

        var pipedStdout = new Pipe(popen.stdout.asInputStream(), stdoutCapture.asOutputStream(), firstIO);
        var pipedStderr = new Pipe(popen.stderr.asInputStream(), stderrCapture.asOutputStream(), firstIO);

        pipedStdout.run();
        pipedStderr.run();

        popen.wait();

        var result = 
            {
                exitCode: popen.returncode,
                stderr: stderrCapture.getBytes().asString(),
                stdout: stdoutCapture.getBytes().asString(),
            }

        Logger.trace("" + result.exitCode);
        if ( result.exitCode != 0 && failOnNonZeroExitCode ) {
            throw result;
        }

        return result;

    }

}


typedef ExecCaptureResult = {
    stdout: String,
    stderr: String,
    exitCode: Int
}




