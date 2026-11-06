
(* Each malformed construct is followed by a synchronization token. *)

(* Bad feature, then a valid feature in the same class. *)
class FeatureErrors {
  broken(a : Int : Int;
  ok : Int <- 0;
};

(* Bad class body, then a valid class: class-level recovery. *)
class BrokenClass {
  missing : Int <- ;
};

class AfterClassError {
  value : Int <- 1;
};

(* Bad let binding and an expression error inside a block. *)
class ExprErrors {
  test() : Int {
    {
      let a : Int <- 1, : Int <- 2 in a;
      1 + ;
      3;
    }
  };
};
