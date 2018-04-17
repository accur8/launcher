package a8;


class DateOps {

    public static function midnight(): Date {
        var now = Date.now();
        var oneSecondBeforeMidnight = new Date(now.getFullYear(), now.getMonth(), now.getMinutes(), 23, 59, 59);
        return Date.fromTime(oneSecondBeforeMidnight.getTime() + 1000);
    }

}