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
}


@:tink
class MidnightLogRoller implements LogRoller {

    var launcher: Launcher = _;

    public function new(_) {
        schedule();
    }

    function schedule() {
        var now = Date.now();
        var midnight = DateOps.midnight();
        var millisToMidnight = midnight.getTime() - now.getTime();
        var secondsToMidnight = millisToMidnight / 1000;
        Main.scheduler.enter(secondsToMidnight, 1.0, doMidnightRollover);
    }

    function doMidnightRollover() {
        var timestampStr = Main.timestampStr();
        // we want the details and error files to have same timestamp
        launcher.pipedStderr.rollover(timestampStr);
        launcher.pipedStdout.rollover(timestampStr);
        schedule();
    }

}

class UnknownLogRoller implements LogRoller {

    public function new(config: Dynamic) {
    }

}