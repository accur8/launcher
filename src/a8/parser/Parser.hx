package a8.parser;


import haxe.ds.Option;
import a8.parser.ParseResult;

using a8.parser.ParseResultOps;


abstract Tuple2<A,B>(Array<Any>) {


    public var _1(get, never): A;
    public var _2(get, never): B;


    inline public function new(a: A, b: B) {
        this = [a, b];
    }

    inline public function get__1(): A {
        return this[0];
    }

    inline public function get__2(): B {
        return this[1];
    }

    inline public function toString(): String {
        return haxe.Json.stringify(this);
    }

}


@:tink
class ParserOps {

    public static var SuccessParser(default, null): Parser<Void> = new SuccessParser();
    public static var EndOfInputParser(default, null): Parser<Void> = new EndOfInputParser();
    public var digits(default, null): Parser<String> = charsWhile([ch]=>"0123456789".indexOf(ch) >= 0);

    public function str(s: String): Parser<String>  {
        return new StringParser(s);
    }

    public function charsWhile(fn: String->Bool): Parser<String> {
        return new CharsWhileParser(function(ch, index) {
            return fn(ch);
        });
    }

    public function charsWhileI(fn: String->Int->Bool): Parser<String> {
        return new CharsWhileParser(fn);
    }

    /**
     * parses a single character
     */
    public function char(fn: String->Bool): Parser<String> {
        return new CharsWhileParser(function(ch, index) {
            return
                if ( index == 0 )
                    fn(ch);
                else
                    false;
        });
    }

}

// class MacroHelper {

//     // // This macro generates code using Context.parse()
//     //   public static macro function trace_build_age_with_parse() {
//     //     var buildTime = Math.floor(Date.now().getTime() / 1000);

//     //     var code = '{
//     //       var runTime = Math.floor(Date.now().getTime() / 1000);
//     //       var age = runTime - $buildTime;
//     //       trace("Right now it\'s "+runTime+", and this build is "+age+" seconds old");
//     //     }';

//     //     return Context.parse(code, Context.currentPos());
//     //   }

//     // public macro static function flattenTuple<A>(e0: ExprOf<Parser<A>>): Void {
//     //     // trace(e.toString()); // @:this this
//     //     // TInst(String,[])
//     //     trace(Context.typeof(e0));
//     // }


// }


@:tink
class Source {

    public var value: String;

    public function new(value: String) {
        this.value = value;
    }

}



@:tink 
abstract Parser<A>(SnippetParser<A>) {

    @:from
    static inline public function fromString(s:String): Parser<String> {
        return new Parser(new StringParser(s));
    }

    @:from
    static inline public function fromSnippetParser<A>(p: SnippetParser<A>): Parser<A> {
        return new Parser(p);
    }

    inline public function new(snippetParser: SnippetParser<A>) {
        this = snippetParser;
    }

    inline private function self(): SnippetParser<A> {
        return cast this;
    }

    public function parse(source: Source): ParseResult<A> {
        return self().parse(source, new Position(0));
    }

    @:to
    inline public function toSnippetParser(): SnippetParser<A> {
        return this;
    }    

    @:op(A * B)
    inline public function andThen<B>(rhs: Parser<B>): Parser<Tuple2<A,B>> {
        return cast new Parser(new AndParser(self(), rhs.self()));
    }

    @:op(A << B)
    inline public function land<B>(rhs: Parser<B>): Parser<A> {
        return cast new Parser(new MapParser(new AndParser(self(), rhs.self()), function(t) { return t._1; }));
    }

    @:op(A >> B)
    inline public function rand<B>(rhs: Parser<B>): Parser<B> {
        return cast new Parser(new MapParser(new AndParser(self(), rhs.self()), function(t) { return t._2; }));
    }

    @:op(A | B)
    inline public function or(rhs: Parser<A>): Parser<A> {
        return new Parser(new OrParser([self(), rhs.self()]));
    }

    inline public function opt(): Parser<Option<A>> {
        return cast new Parser(new OptParser(self()));
    }

    inline public function map<B>(fn: A->B): Parser<B> {
        return new Parser(new MapParser(self(), fn));
    }

    // inline public function ws0(): Parser<A> {
    //     return new Parser(new MapParser(self(), function(i) { return null; } ));
    // }

    // inline public function ws(): Parser<A> {
    //     return new Parser(new MapParser(self(), function(i) { return null; } ));
    // }

    inline public function void(): Parser<Void> {
        return new Parser(new MapParser(self(), function(i) { return null; } ));
    }

    inline public function filter(fn: A->Bool): Parser<A> {
        return new Parser(new FilterParser(self(), fn));
    }

    inline public function capture(): Parser<String> {
        return new CaptureParser(self());
    }

    /**
     *   Run this parser to the end of the input
     */
    inline public function fullParse(source: String): ParseResult<A> {
        var parseToEnd = land(ParserOps.EndOfInputParser);
        return parseToEnd.self().parse(new Source(source), new Position(0));
    }

    inline public function rep(?options: {?min: Int, ?max: Int}): Parser<Array<A>> {
        if ( options == null ) {
            options = {};
        }
        return cast new Parser(new RepeatSeparatorParser(self(), ParserOps.SuccessParser, options.min, options.max));
    }

    inline public function rep0(): Parser<Array<A>> {
        return rep({min: 0});
    }

    inline public function repsep(separator: Parser<Dynamic>, ?options: { ?min: Int, ?max: Int}): Parser<Array<A>> {
        if ( options == null ) {
            options = {};
        }
        return cast new Parser(new RepeatSeparatorParser(self(), separator, options.min, options.max));
    }

    inline public function repsep0(separator: Parser<Dynamic>): Parser<Array<A>> {
        return repsep(separator, {min: 0});
    }

    inline public function log(?posInfos: haxe.PosInfos): Parser<A> {
        return new LogParser(self(), posInfos);
    }

}


interface SnippetParser<A> {
    function parse(source: Source, pos: Position): ParseResult<A>;
}


@:tink
class LogParser<A> 
    implements SnippetParser<A> {

    var parser: SnippetParser<A> = _;
    var posInfos: haxe.PosInfos = _;

    public function parse(source: Source, pos: Position): ParseResult<A> {
        var r = parser.parse(source, pos);
        haxe.Log.trace(r, posInfos);
        return r;
    }

}


@:tink
class FilterParser<A> 
    implements SnippetParser<A> {

    var parser: SnippetParser<A> = _;
    var filterFn: A -> Bool = _;

    public function parse(source: Source, pos: Position): ParseResult<A> {
        var result = parser.parse(source, pos);
        return
            switch (result) {
                case ParseFailure(_, _):
                    result;
                case ParseSuccess(_, r):
                    var a: A = cast r;
                    if ( filterFn(a) ) {
                        result;
                    } else {
                        ParseFailure(pos, "failed filter");
                    }
            };
    }

}


@:tink
class OptParser<A>
    implements SnippetParser<Option<A>> {

    var parser: SnippetParser<A> = _;

    public function parse(source: Source, pos: Position): ParseResult<Option<A>> {
        var result = parser.parse(source, pos);
        return
            switch (result) {
                case ParseFailure(_, _):
                    ParseSuccess(
                        pos,
                        None
                    );
                case ParseSuccess(to, r):
                    var a: A = cast r;
                    ParseSuccess(
                        to,
                        Some(a)
                    );
            };
    }

}


@:tink
class CaptureParser<A>
    implements SnippetParser<String> {

    var parser: SnippetParser<A> = _;

    public function parse(source: Source, pos: Position): ParseResult<String> {
        var result = parser.parse(source, pos);
        return
            switch (result) {
                case ParseFailure(_, _):
                    cast result;
                case ParseSuccess(to, r):
                    ParseSuccess(
                        to,
                        source.value.substring(pos.index, to.index)
                    );
            };
    }

}

@:tink
class OrParser<A> 
    implements SnippetParser<A> {

    var parsers: Array<SnippetParser<A>> = _;

    public function parse(source: Source, pos: Position): ParseResult<A> {
        var result: ParseResult<A> = null;
        for (parser in parsers) {
            result = parser.parse(source, pos);
            switch(result) {
                case ParseFailure(_):
                case s = ParseSuccess(_, _):
                    return s;
            }
        }
        return result;
    }

}

@:tink
class LazyParser<A>
    implements SnippetParser<A> {

    var lazyFn: Void->Parser<A> = _;
    var delegateParser: SnippetParser<A> = null;

    public function parse(source: Source, pos: Position): ParseResult<A> {
        if ( delegateParser == null) {
            delegateParser = lazyFn().toSnippetParser();
        }
        return delegateParser.parse(source, pos);
    }


}

@:tink
class AndParser<A,B> 
    implements SnippetParser<Tuple2<A,B>> {

    var parserA: SnippetParser<A> = _;
    var parserB: SnippetParser<B> = _;

    public function parse(source: Source, pos: Position): ParseResult<Tuple2<A,B>> {
        var resultA = parserA.parse(source, pos);
        return 
            switch( resultA ) {
                case ParseFailure(_, _):
                    cast resultA;
                case s = ParseSuccess(_, valueA):
                    var resultB = parserB.parse(source, s.nextPosition());
                    switch ( resultB ) {
                        case ParseFailure(_, _):
                            cast resultB;
                        case ParseSuccess(to, valueB):
                            ParseSuccess(
                                to,
                                new Tuple2(valueA, valueB)
                            );
                    }
            }
    }

}

@:tink
class CharsWhileParser
    implements SnippetParser<String> {

    var whileFn: String->Int->Bool = _;

    public function parse(source: Source, pos: Position): ParseResult<String> {
        var cont = true;
        var offset = 0;
        var index = pos.index;
        while( cont && index < source.value.length ) {
            var ch = source.value.charAt(index);
            cont = whileFn(ch, offset);
            if ( cont ) {
                index += 1;
                offset += 1;
            }
        }
        return 
            if ( index != pos.index ) {
                ParseSuccess(new Position(index), source.value.substring(pos.index, index));
            } else {
                ParseFailure(pos, "no chars match at " + pos);
            }
    }

}

@:tink
class StringParser 
    implements SnippetParser<String> {

    var matchMe: String = _;

    public function parse(source: Source, pos: Position): ParseResult<String> {
        var len = matchMe.length;
        var i = 0;
        while ( i < len ) {
            if ( source.value.charAt(pos.index + i) == matchMe.charAt(i) ) {
                i += 1;
            } else {
                return ParseFailure(pos, "no match for " + matchMe + " at " + pos);
            }
        }
        return ParseSuccess(new Position(pos.index + len), matchMe);
    }

}

@:tink
class MapParser<A,B> 
    implements SnippetParser<B> {

    var parser: SnippetParser<A> = _;
    var mapFn: A -> B = _;

    public function parse(source: Source, pos: Position): ParseResult<B> {
        var result = parser.parse(source, pos);
        return
            switch(result) {
                case ParseSuccess(to, v):
                    var a: A = cast v;
                    ParseSuccess(
                        to,
                        mapFn(a)
                    );
                case ParseFailure(_, _):
                    cast result;    
            };
    }

}


class RepeatSeparatorParser<A> 
    implements SnippetParser<Array<A>> {

    var elementParser: SnippetParser<A>;
    var separatorParser: SnippetParser<Dynamic>;
    var min: Int;
    var max: Int;

    public function new(elementParser: SnippetParser<A>, separatorParser: SnippetParser<Dynamic>, ?min: Int, ?max: Int) {
        this.elementParser = elementParser;
        this.separatorParser = separatorParser;
        this.min = min != null ? min : 0;
        this.max = max != null ? max : 2147483647;
    }

    public function parse(source: Source, pos: Position): ParseResult<Array<A>> {

        var items: Array<A> = [];

        var iterPos = pos;

        switch ( elementParser.parse(source, iterPos) ) {

            case f = ParseFailure(_):
                if ( min == 0 ) {
                    return ParseSuccess(
                        pos,
                        items
                    );
                } else {
                    return cast f;
                }

            case ParseSuccess(to, a):
                items.push(cast a);
                iterPos = to;

        }

        var lastFailure = null;
        var cont = true;

        while ( cont && items.length < max ) {

            switch ( separatorParser.parse(source, iterPos) ) {

                case f = ParseFailure(_):
                    lastFailure = f;
                    cont = false;

                case ParseSuccess(to, _):
                    iterPos = to;

            }

            if ( cont ) {

                switch ( elementParser.parse(source, iterPos) ) {

                    case f = ParseFailure(_):
                        cont = false;

                    case ParseSuccess(to, a):
                        iterPos = to;
                        items.push(cast a);

                }
            }


        }

        return 
            if ( min > items.length ) {
                ParseFailure(pos, "found " + items.length + " expected a minimum of " + min);
            } else {   
                ParseSuccess(
                    iterPos,
                    items
                );
            };

    }

}

class SuccessParser<Void> 
    implements SnippetParser<Void> {

    public function new() {
    }

    public function parse(source: Source, pos: Position): ParseResult<Void> {
        return 
            ParseSuccess(
                pos,
                null
            );
    }

}


class EndOfInputParser<Void> 
    implements SnippetParser<Void> {

    public function new() {
    }

    public function parse(source: Source, pos: Position): ParseResult<Void> {
        return 
            if ( pos.index == source.value.length ) {
                ParseSuccess(pos, null);
            } else {
                ParseFailure(pos, "expected end of input");
            };
    }

}

