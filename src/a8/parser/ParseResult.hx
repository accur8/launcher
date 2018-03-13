package a8.parser;


import a8.parser.Position;

enum ParseResult<A> {
    
    ParseSuccess<A>(
        to: Position,
        result: A
    );

    ParseFailure<A>(
        at: Position,
        msg: String
    );

}

