package a8;





import haxe.ds.Option;


class OptionOps {

    public static function nonEmpty<A>(o: Option<A>): Bool {
        return 
            switch o {
                case Some(_): true;
                case None: false;
            }
    }

    public static function isEmpty<A>(o: Option<A>): Bool {
        return !nonEmpty(o);
    }


    public static function getOrError<A>(o: Option<A>, msg: String): A {
        return 
            switch o {
                case Some(i): i;
                case None: throw msg;
            }
    }

    public static function getOrElse<A>(o: Option<A>, def: A): A {
        return 
            switch o {
                case Some(i): i;
                case None: def;
            }
    }

    public static function get<A>(o: Option<A>, def: A): A {
        return getOrError(o, "expected a Some");
    }

    public static function iter<A>(o: Option<A>, fn: A->Void): Void {
        return 
            switch o {
                case Some(a): fn(a);
                case None: 
            }
    }

}








