package a8;


import a8.Main;
import a8.DateOps;

class LogRollerOps {
    public static function fromConfig(c: Dynamic, launcher: Launcher): LogRoller {
        return 
            if ( c == "midnight") {
                new MidnightLogRoller(launcher);
            } else {
                new UnknownLogRoller(c);
            }
    }
    public static function scheduleAtMidnight(fn: Void->Void) {
        var now = Date.now();
        var midnight = DateOps.midnight();
        var millisToMidnight = midnight.getTime() - now.getTime();
        var secondsToMidnight = millisToMidnight / 1000;
        Main.scheduler.enter(secondsToMidnight, 1.0, fn);
    }
}

interface LogRoller {
    function init(): Void;
    function onArchiveLogChanges(): Void;
}

class AbstractLogRoller {
    public function init(): Void {
    }
    public function onArchiveLogChanges(): Void {
    }
}


@:tink
class MidnightLogRoller extends AbstractLogRoller implements LogRoller {

    var launcher: Launcher = _;

    override public function init(): Void {
        schedule();
    }

    function schedule() {
        LogRollerOps.scheduleAtMidnight(doMidnightRollover);
    }

    function doMidnightRollover() {
        launcher.logDetail("running doMidnightRollover");
        var timestampStr = Main.timestampStr();
        // we want the details and error files to have same timestamp
        launcher.pipedStderr.rollover(timestampStr);
        launcher.pipedStdout.rollover(timestampStr);
        schedule();
        launcher.logDetail("doMidnightRollover complete");
    }

}

@:tink
class UnknownLogRoller extends AbstractLogRoller implements LogRoller {

    var config: Dynamic = _;

    public function new(_) {
    }    

}

@:tink
class CullOldArchivesLogRoller extends AbstractLogRoller implements LogRoller {

    var config: Dynamic = _;
    var launcher: Launcher = _;

    public function new(_) {
    }    

    override public function init(): Void {
        Main.scheduler.enter(0, 1.0, cullOldLogs);
        LogRollerOps.cullOldLogs();
    }

    function cullOldLogs() {
        // read log files here
    }

}
