package a8.parser;


import a8.parser.ParseResult;

class ParseResultOps {

    public static function nextPosition<A>(s: ParseResult<A>): Position {
        return
            switch(s) {
                case ParseSuccess(to, _):
                    to;
                case _:
                    throw new Exception("unable to get a to from a ParseFailure");
            }
    }

}

