package a8.parser;


import a8.parser.Parser;

class ParserMacros {

/*

    !A         - negative lookahead
    &A         - positive lookahead
    A.?        - .opt() 
    A.rep()    - function suffix

    log()
        properly indented
    Start
    Index
    named parsers

  == done ==
    A ~ B      - andThen()
    A | B      - or()
    (A)        - parens
    "str"      - string literal
    123        - numeric literal

*/


}


@:tink
class HaxeExprParser extends ParserOps {

    public function new() {
        super();
    }

    function P<A>(lazyFn: Void->Parser<A>): Parser<A> {
        return new LazyParser(lazyFn);
    }

    public function parse(exprStr: String): a8.parser.ParseResult<Expr> {
        return expr.fullParse(exprStr);
    }

    var expr: Parser<Expr> = P([] => {
        atom.andThen(binOpSuffix.opt())
            .map(function(t: Tuple2<Expr,Option<Tuple2<String,Expr>>>): Expr {
                var e = 
                    switch t._2 {
                        case None:
                            t._1;
                        case Some(v):
                            BinOp(t._1, v._1, v._2);
                    }
                return e;
            });
    });

    var binOpSuffix: Parser<Tuple2<String,Expr>> = P([]=>
        operator.andThen(expr)
    );


    var atom: Parser<Expr> = P([] => 
        lws(
            functionCall
            | name
            | parens
            | number
            | stringLit
        )
    );

    var operator: Parser<String> = P([] =>
        op("~")
        | op("|")
    );

    var parens: Parser<Expr> = P([] =>
        (lws(str("(")) >> expr << lws(str(")")))
            .map([e] => Parens(e))
    );

    var name: Parser<Expr> = P([] =>
        identifier
            .map([n] => Var(n))
    );

    var identifier: Parser<String> = P([] =>
        charsWhileI([ch, i] => {
            if ( i == 0 )
                ch.isHaxeIdentifierFirstChar();
            else
                ch.isHaxeIdentifierSecondChar();
        })
    );


    var dot: Parser<String> = P([]=>lws(str(".")));

    var number: Parser<Expr> = P([]=>
        (digits.andThen(dot).andThen(digits.opt()).capture())
        .or(
            dot.andThen(digits).capture()
        ).or(
            digits.capture()
        )
    )
        .capture()
        .map([s] => Number(s.trim()))
        ;

    var whitespace: Parser<String> = P([]=>charsWhile([ch] => ch.isWhitespace()));

    var functionCall: Parser<Expr> = P([] =>
        ((identifier << lparen) * (expr.repsep(comma) << rparen))
            .map([t] => FunctionCall(t._1, t._2))
    );

    var comma: Parser<String> = P([] => lws(str(",")));
    var lparen: Parser<String> = P([] => lws(str("(")));
    var rparen: Parser<String> = P([] => lws(str(")")));

    var stringLit: Parser<Expr> = P([] => {
        var quoteChar = '"';
        (lws(quoteChar) >> charsWhile([ch] => ch != quoteChar) << quoteChar)
            .map([s] => StringLit(s));
    });

    function lws<A>(parser: Parser<A>): Parser<A> {
        return whitespace.opt() >> parser;
    }

    function op(operator: String): Parser<String> {
        return lws(str(operator));
    }

}



enum Expr {
    Var(name: String);
    BinOp(left: Expr, op: String, right: Expr);
    Parens(inside: Expr);
    Number(value: String);
    StringLit(value: String);
    FunctionCall(name: String, parms: Iterable<Expr>);
}
