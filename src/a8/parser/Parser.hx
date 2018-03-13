package a8.parser;


import haxe.ds.Option;
import a8.parser.ParseResult;

using Lambda;
using a8.parser.ParseResultOps;


abstract Tuple2<A,B>(Array<Any>) {

  inline public function new(a: A, b: B) {
    this = [a, b];
  }

  inline public function _1(): A {
    return this[0];
  }

  inline public function _2(): B {
    return this[1];
  }

  inline public function toString(): String {
    return haxe.Json.stringify(this);
  }

}

class ParserHelper {

    public static var SuccessParser: Parser<Void> = new SuccessParser();
    public static var EndOfInputParser: Parser<Void> = new EndOfInputParser();

}


class Source implements a8.ValueClass {
    var value: String;
}


@:tink 
class ParserBuilder {

    public function str(s: String): Parser<String>  {
        return new StringParser(s);
    }

}


@:tink 
abstract Parser<A>(SnippetParser<A>) {

    @:from
    inline static public function fromString(s:String): Parser<String> {
        return new Parser(new StringParser(s));
    }

    @:from
    inline static public function fromSnippetParser<A>(p: SnippetParser<A>): Parser<A> {
        return new Parser(p);
    }

    @:to
    inline public function toSnippetParser(): SnippetParser<A> {
        return this;
    }

    inline public function new(parseFn: SnippetParser<A>) {
        this = parseFn;
    }

    inline private function self(): SnippetParser<A> {
        return cast this;
    }

    @:op(A & B)
    inline public function and<B>(rhs: Parser<B>): Parser<Tuple2<A,B>> {
        return cast new Parser(new AndParser(self(), rhs.self()));
    }

    @:op(A << B)
    inline public function land<B>(rhs: Parser<B>): Parser<A> {
        return cast new Parser(new MapParser(new AndParser(self(), rhs.self()), function(t) { return t._1; }));
    }

    @:op(A >> B)
    inline public function rand<B>(rhs: Parser<B>): Parser<B> {
        return cast new Parser(new MapParser(new AndParser(self(), rhs.self()), function(t) { return t._1; }));
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

    inline public function ws0(): Parser<A> {
        return new Parser(new MapParser(self(), function(i) { return null; } ));
    }

    inline public function ws(): Parser<A> {
        return new Parser(new MapParser(self(), function(i) { return null; } ));
    }

    inline public function void(): Parser<Void> {
        return new Parser(new MapParser(self(), function(i) { return null; } ));
    }

    inline public function filter(fn: A->Bool): Parser<A> {
        return new Parser(new FilterParser(self(), fn));
    }

    /**
     *   Run this parser to the end of the input
     */
    inline public function fullParse(source: String): ParseResult<A> {
        var parseToEnd = land(ParserHelper.EndOfInputParser);
        return parseToEnd.self().parse(new Source(source), new Position(0));
    }

    inline public function rep(options: {?min: Int, ?max: Int}): Parser<Array<A>> {
        return cast new Parser(new RepeatSeparatorParser(self(), ParserHelper.SuccessParser, options.min, options.max));
    }

    inline public function rep0(): Parser<Array<A>> {
        return rep({min: 0});
    }

    inline public function repsep(separator: Parser<Any>, options: { ?min: Int, ?max: Int}): Parser<Array<A>> {
        return cast new Parser(new RepeatSeparatorParser(self(), separator, options.min, options.max));
    }

    inline public function repsep0(separator: Parser<Any>): Parser<Array<A>> {
        return repsep(separator, {min: 0});
    }

}


interface SnippetParser<A> {
    function parse(source: Source, pos: Position): ParseResult<A>;
}


class FilterParser<A> 
    implements SnippetParser<A> 
    implements ValueClass {

    var parser: SnippetParser<A>;
    var filterFn: A -> Bool;

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


class OptParser<A>
    implements SnippetParser<Option<A>>
    implements ValueClass {

    var parser: SnippetParser<A>;

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

class OrParser<A> 
    implements SnippetParser<A> 
    implements ValueClass {

    var parsers: Array<SnippetParser<A>>;

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


class AndParser<A,B> 
    implements SnippetParser<Tuple2<A,B>> 
    implements ValueClass {

    var parserA: SnippetParser<A>;
    var parserB: SnippetParser<B>;

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

class StringParser 
    implements SnippetParser<String> 
    implements ValueClass {

    var matchMe: String;

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


class MapParser<A,B> 
    implements SnippetParser<B> 
    implements ValueClass {

    var parser: SnippetParser<A>;
    var mapFn: A -> B;

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
    implements SnippetParser<Void> 
    implements ValueClass {

    public function parse(source: Source, pos: Position): ParseResult<Void> {
        return 
            ParseSuccess(
                pos,
                null
            );
    }

}


class EndOfInputParser<Void> 
    implements SnippetParser<Void> 
    implements ValueClass {

    public function parse(source: Source, pos: Position): ParseResult<Void> {
        return 
            if ( pos.index == source.value.length ) {
                ParseSuccess(pos, null);
            } else {
                ParseFailure(pos, "expected end of input");
            };
    }

}


