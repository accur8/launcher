package a8;


import a8.PyOps;

@:tink
class GlobalScheduler {

    public static var scheduler = {
        var s = PySched.scheduler();
        PyOps.spawn({ [] =>
            while(true) {
                s.run();
                python.lib.Time.sleep(1);
            }
        });
        s;
    }


    public static function schedule(delayInSeconds: Float, fn: Void->Void): Void {
        scheduler.enter(delayInSeconds, 1.0, fn);
    }

    public static function submit(fn: Void->Void): Void {
        schedule(0, fn);
    }


}