package a8.parser;


import a8.parser.Parser;
import a8.parser.ParserMacros;

class ParserDemo {


    public static function main(): Void {
    
        var p = new HaxeExprParser();

        trace(p.parse("xyz"));
        trace(p.parse("123"));
        trace(p.parse("123~xxxyz"));
        trace(p.parse("(123~xxxyz) | 456"));
        trace(p.parse("123~xxxyz~456~abc~xxxyz~456~abc~xxxyz~456~abc~xxxyz~456~abc"));
        trace(p.parse("123 ~~ xxxyz"));
        trace(p.parse("123 ~ xxxyz(f00, 123)"));

    }

}


@:tink
class DemoParser extends ParserOps {

    var foo: Parser<String> = "123";

    @:lazy var abc: Parser<String> = str("abc");
    @:lazy var xyz: Parser<String> = str("xyz");

    @:lazy var top = (abc | xyz);

    public function new() {
        super();
    }

    public function parse(source: String): Void {
        trace(source + " -- " + top.fullParse(source));
    }

}