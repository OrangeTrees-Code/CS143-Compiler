(* A collection of legal Cool programs covering classes, attributes,
   methods, formals, every expression form, dispatch, and list syntax. *)
class Main inherits IO {
  count : Int;
  text : String <- "hello\nworld";

  main(a : Int, b : String) : Object {
    {
      count <- a + 1 * 2 - 3 / 1;
      if not count < 10 then count else ~a fi;
      while count < 10 loop count <- count + 1 pool;
      case count of i : Int => i; s : String => 0; esac;
      let x : Int, y : Int <- 2, z : String <- b in x + y;
      new Main;
      isvoid self;
      self@IO.out_string(text);
      out_int(count);
      count;
    }
  };

  ping() : Int { count };
};

class Empty {
};
