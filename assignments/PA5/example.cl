-- Exercises inherited state, overrides, both dispatch forms and SELF_TYPE.
class A {
  value : Int <- 4;
  set(x : Int) : SELF_TYPE { { value <- x; self; } };
  get() : Int { value };
  make() : SELF_TYPE { new SELF_TYPE };
};
class B inherits A {
  get() : Int { value + 1 };
};
class Main inherits IO {
  main() : Object {
    let a : A <- (new B).set(9), i : Int <- 0, total : Int <- 0 in {
      out_int(a.get()); out_string(" ");
      out_int(a@A.get()); out_string(" ");
      out_string(a.make().type_name()); out_string(" ");
      case a of
        x : Object => out_string("Object");
        x : A => out_string("A");
        x : B => out_string("B");
      esac;
      while i < 4 loop { total <- total + i; i <- i + 1; } pool;
      out_string(" "); out_int(total); out_string(" ");
      out_int((10 - 2) * 3 / 2); out_string(" "); out_int(~5);
      if not (isvoid a) then out_string(" ok") else out_string(" bad") fi;
      if "ab".concat("c") = "abc" then out_string(" equal\n") else out_string(" unequal\n") fi;
    }
  };
  and_test() : Bool { 1 <= 1 };
};
