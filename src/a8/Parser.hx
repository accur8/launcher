import a8;



using Lambda;


class ParserTools {

    static var _parseFailure = new ParseFailure();

    static function parseFailure<A>(): ParseFailure<A> {
        return _parseFailure;
    }

}


class Input implements ValueClass {

    var source: String;
    var from: Int;
    var to: Int;

}


interface ParseResult<A> {
    function success(): Bool;
    function resultOpt(): Option<A>
}


class ParseSuccess<A> implements ParseResult<A> implements ValueClass{
    
    var input: Input
    var consumed: Input

    var result: A

    // lazily calculated
    var newInput: Input

}


class ParseFailure<A> implements ValueClass implements ParseResult<A> {

    public function success(): Bool {
        return false;
    }

}


interface Parser<A> {

    public function parse(input: Input): ParseResult<A>;

}


class FilterParser<A> implements Parser<A> implements ValueClass {

    var parser: Parser<A>;
    var filter: A -> Bool;

    public function parse(input: Input): ParseResult<A> {
        var result = parser.parse(input);
        return
            switch (result.resultOpt()) {
                case None:
                    result;
                case Some(r):
                    if ( filter(r) ) {
                        result
                    } else {
                        ParserTools.parseFailure<A>();
                    }
            };
    }

}


class OrParser<A> implements Parser<A> implements ValueClass {

    var parsers: Array<Parser<A>>;

    public function parse(input: Input): ParseResult<A> {
        for (parser in parsers) {
            var result = parser.parse(input);
            if ( result.success() ) {
                return result;
            }
        }
        return ParserTools.parseFailure<A>();
    }

}


class AndParser<A,B> implements Parser<A> implements ValueClass {

    var parsers: Array<Parser<A>>;

    public function parse(input: Input): ParseResult<A> {
        var ongoingInput = input;
        for (parser in parsers) {
            var result = parser.parse(input);
            if ( result.success() ) {
                return result;
            } else {
                return result;
            }
        }
        // ??? TODO make new result here
        return ;
    }

}


class MapParser<A,B> implements Parser<B> implements ValueClass {

    var parser: Parser<A>;
    var mapFn: A -> B;

    public function parse(input: Input): ParseResult<A> {
        var result = parser.parse(input);
        return
            switch(result.resultOpt()) {
                case Some(r):
                    new ParseSuccess<B>(
                        input = result.input,
                        consumed = result.consumed,
                        result = mapFn(r)
                    )
                case None:
                    result;    
            };
    }

}




