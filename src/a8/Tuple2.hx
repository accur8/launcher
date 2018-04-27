package a8;


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


