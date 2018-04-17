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
        var now = Date.now();
        var midnight = DateOps.midnight();
        var millisToMidnight = midnight.getTime() - now.getTime();
        var secondsToMidnight = millisToMidnight / 1000;
        launcher.logDetail("schedule log rolling in " + secondsToMidnight + " seconds");
        Main.scheduler.enter(secondsToMidnight, 1.0, doMidnightRollover);
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

}
