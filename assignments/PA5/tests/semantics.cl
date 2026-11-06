class Cell {
  item : Object;
  put(x : Object) : Object { item <- x };
  get() : Object { item };
};
class Main inherits IO {
  sum(a : Int, b : Int, c : Int) : Int { a * 100 + b * 10 + c };
  main() : Object {
    let c : Cell <- new Cell, i : Int <- 0, x : Int in {
      out_int(sum(1, 2, 3)); out_string(" ");
      out_int(let x : Int <- 7 in (let x : Int <- x + 1 in x) + x); out_string(" ");
      out_int(x); out_string(" ");
      while i < 100 loop { c.put((new Object).copy()); i <- i + 1; } pool;
      if isvoid c.get() then out_string("bad") else out_string("live") fi;
      if (new Object) = (new Object) then out_string(" bad") else out_string(" distinct") fi;
      if (1 + 1) = 2 then out_string(" equal") else out_string(" bad") fi;
      if 2 <= 2 then out_string(" leq\n") else out_string(" bad\n") fi;
    }
  };
};
