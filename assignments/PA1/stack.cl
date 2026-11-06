(*
 * CS164 Fall 94
 * Programming Assignment 1: a simple stack machine.
 *)

class StackNode {
   value : String;
   next : StackNode;

   init(val : String, nxt : StackNode) : SELF_TYPE {
      {
         value <- val;
         next <- nxt;
         self;
      }
   };

   getValue() : String { value };

   getNext() : StackNode { next };
};

class Stack inherits IO {
   top : StackNode;

   push(value : String) : SELF_TYPE {
      {
         top <- (new StackNode).init(value, top);
         self;
      }
   };

   pop() : String {
      let node : StackNode <- top in {
         top <- node.getNext();
         node.getValue();
      }
   };

   topValue() : String { top.getValue() };

   isEmpty() : Bool { isvoid top };

   print() : SELF_TYPE {
      let current : StackNode <- top in {
         while not isvoid current loop {
            out_string(current.getValue());
            out_string("\n");
            current <- current.getNext();
         } pool;
         self;
      }
   };
};

class StackCommand {
   eval(stack : Stack) : SELF_TYPE { self };
};

class PushCommand inherits StackCommand {
   value : String;

   init(val : String) : SELF_TYPE {
      {
         value <- val;
         self;
      }
   };

   eval(stack : Stack) : SELF_TYPE {
      {
         stack.push(value);
         self;
      }
   };
};

class EvaluateCommand inherits StackCommand {
   eval(stack : Stack) : SELF_TYPE {
      if stack.isEmpty() then
         self
      else
         (let op : String <- stack.topValue() in
            if op = "+" then
               {
                  stack.pop();
                  (let converter : A2I <- new A2I in
                     (let first : Int <- converter.a2i(stack.pop()) in
                        (let second : Int <- converter.a2i(stack.pop()) in {
                           stack.push(converter.i2a(first + second));
                           self;
                        }
                     )
                  )
                  );
               }
            else
               if op = "s" then
                  {
                     stack.pop();
                     (let first : String <- stack.pop() in
                        (let second : String <- stack.pop() in {
                           stack.push(first);
                           stack.push(second);
                           self;
                        }
                     )
                  );
               }
               else
                  self
               fi
            fi
         )
      fi
   };
};

class DisplayCommand inherits StackCommand {
   eval(stack : Stack) : SELF_TYPE {
      {
         stack.print();
         self;
      }
   };
};

class AbortCommand inherits StackCommand {
   kernel : Kernel;

   init(k : Kernel) : SELF_TYPE {
      {
         kernel <- k;
         self;
      }
   };

   eval(stack : Stack) : SELF_TYPE {
      {
         kernel.shutdown();
         self;
      }
   };
};

class Parser {
   parse(command : String, kernel : Kernel) : StackCommand {
      if command = "x" then
         (new AbortCommand).init(kernel)
      else
         if command = "e" then
            new EvaluateCommand
         else
            if command = "d" then
               new DisplayCommand
            else
               (new PushCommand).init(command)
            fi
         fi
      fi
   };
};

class Executor {
   execute(command : StackCommand, stack : Stack) : Object {
      {
         case command of
            abort : AbortCommand => abort.eval(stack);
            display : DisplayCommand => display.eval(stack);
            evaluate : EvaluateCommand => evaluate.eval(stack);
            push : PushCommand => push.eval(stack);
            generic : StackCommand => generic.eval(stack);
         esac;
         self;
      }
   };
};

class Shell inherits IO {
   parser : Parser;
   executor : Executor;

   init() : SELF_TYPE {
      {
         parser <- new Parser;
         executor <- new Executor;
         self;
      }
   };

   run(stack : Stack, kernel : Kernel) : SELF_TYPE {
      let command : StackCommand in {
         out_string(">");
         command <- parser.parse(in_string(), kernel);
         executor.execute(command, stack);
         self;
      }
   };
};

class Kernel {
   shell : Shell;
   stack : Stack;
   shouldExit : Bool;

   init() : SELF_TYPE {
      {
         shell <- (new Shell).init();
         stack <- new Stack;
         shouldExit <- false;
         self;
      }
   };

   shutdown() : SELF_TYPE {
      {
         shouldExit <- true;
         self;
      }
   };

   run() : SELF_TYPE {
      {
         while not shouldExit loop
            shell.run(stack, self)
         pool;
         self;
      }
   };
};

class Main inherits IO {
   main() : Object {
      (new Kernel).init().run()
   };
};
