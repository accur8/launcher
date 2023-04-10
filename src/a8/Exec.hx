package a8;



import python.lib.Subprocess;
import a8.Streams;

@:tink
class Exec {

    public var args: Array<String> = [];
    public var cwd: Option<String> = None;
    public var env: Option<Map<String,String>> = None;
    public var failOnNonZeroExitCode: Bool = true;

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
        Logger.trace('running -- ${asCommandLine()}');
        var exitCode = 
            python.lib.Subprocess.call(
                args,
                {
                    cwd: cwd.getOrElse(null)
                }
            );
        if ( exitCode != 0 && failOnNonZeroExitCode ) {
            a8.Exception.thro('non-zero exit code of ${exitCode} while executing -- ${asCommandLine()}');
        }
        return exitCode;
    }

    /**
      *  Will run the process waiting til completion capturing stdout
      *  and throwing an excpetion on any non-empty data on stderr 
      *  or a non-zero exit code
      */
    public function execCaptureStdout(): String {
        var saveFailOnNonZeroExitCode = this.failOnNonZeroExitCode;
        this.failOnNonZeroExitCode = true;
        var result = execCapture();
        if ( result.stderr.length != 0 ) {
            a8.Exception.thro('non-empty stderr while executing -- ${asCommandLine()} -- ${result.stderr}');
        }
        return result.stdout;
    }

    /**
      *  Will run the process waiting til completion capturing stdout and stderr to separate strings
      */
    public function execCapture(): ExecCaptureResult {
        Logger.trace('running -- ${asCommandLine()}');
        var popen = 
            new python.lib.subprocess.Popen(
                args, 
                null, 
                args[0], 
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
            a8.Exception.thro('non-zero exit code of ${result.exitCode} while executing -- ${asCommandLine()}');
        }

        return result;

    }

}


typedef ExecCaptureResult = {
    stdout: String,
    stderr: String,
    exitCode: Int
}




