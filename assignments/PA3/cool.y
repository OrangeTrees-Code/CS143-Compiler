/*
*  cool.y
*              Parser definition for the COOL language.
*
*/
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"
  
  extern char *curr_filename;
  
  
  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
  for the location of tokens */
    
    extern int node_lineno;          /* set before constructing a tree node
    to whatever you want the line number
    for the tree node to be */
      
      
      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;


    #define SET_NODELOC(Current)  \
    node_lineno = Current;
    
    /* IMPORTANT NOTE ON LINE NUMBERS
    *********************************
    * The above definitions and macros cause every terminal in your grammar to 
    * have the line number supplied by the lexer. The only task you have to
    * implement for line numbers to work correctly, is to use SET_NODELOC()
    * before constructing any constructs from non-terminals in your grammar.
    * Example: Consider you are matching on the following very restrictive 
    * (fictional) construct that matches a plus between two integer constants. 
    * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):
    
    plus_consts	: INT_CONST '+' INT_CONST 
    
    * where INT_CONST is a terminal for an integer constant. Now, a correct
    * action for this rule that attaches the correct line number to plus_const
    * would look like the following:
    
    plus_consts	: INT_CONST '+' INT_CONST 
    {
      // Set the line number of the current non-terminal:
      // ***********************************************
      // You can access the line numbers of the i'th item with @i, just
      // like you acess the value of the i'th exporession with $i.
      //
      // Here, we choose the line number of the last INT_CONST (@3) as the
      // line number of the resulting expression (@$). You are free to pick
      // any reasonable line as the line number of non-terminals. If you 
      // omit the statement @$=..., bison has default rules for deciding which 
      // line number to use. Check the manual for details if you are interested.
      @$ = @3;
      
      
      // Observe that we call SET_NODELOC(@3); this will set the global variable
      // node_lineno to @3. Since the constructor call "plus" uses the value of 
      // this global, the plus node will now have the correct line number.
      SET_NODELOC(@3);
      
      // construct the result node:
      $$ = plus(int_const($1), int_const($3));
    }
    
    */


    
    void yyerror(char *s);        /*  defined below; called for each parse error */
    /* libfl on newer systems references the traditional yylex symbol while
       the supplied scanner exports cool_yylex.  Bison's prefix macro is
       undefined around this compatibility wrapper. */
    #ifdef yylex
    #undef yylex
    #endif
    extern int cool_yylex();
    extern "C" int yylex(void) { return cool_yylex(); }

  /* A small temporary representation is used for comma-separated let
     bindings; it is folded into nested let AST nodes once the body is read. */
  struct LetBinding {
    Symbol name;
    Symbol type;
    Expression init;
    LetBinding *next;
    LetBinding(Symbol n, Symbol t, Expression i)
      : name(n), type(t), init(i), next(NULL) {}
  };
  static Expression make_let(LetBinding *b, Expression body) {
    if (!b) return body;
    return let(b->name, b->type, b->init, make_let(b->next, body));
  }
    
    /************************************************************************/
    /*                DONT CHANGE ANYTHING IN THIS SECTION                  */
    
    Program ast_root;	      /* the result of the parse  */
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}
    
    /* A union of all the types that can be the result of parsing actions. */
    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      LetBinding *let_binding;
      char *error_msg;
    }
    
    /* 
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.
    
    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276 
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279 
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283
    
    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/
    
    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison 
    documentation for details). */
    
    /* Declare types for the grammar's non-terminals. */
    %type <program> program
    %type <classes> class_list
    %type <class_> class
    
    %type <features> dummy_feature_list feature_list
    %type <feature> feature
    %type <formals> formals formal_list
    %type <formal> formal
    %type <expression> expr
    %type <expressions> actuals expr_list expr_list_no_semi
    %type <cases> case_list
    %type <case_> simple_case
    %type <let_binding> let_binding let_bindings

    /* Assignment is right associative.  Dispatch binds tighter than all
       operators, followed by the unary operators, arithmetic, and tests. */
    %right ASSIGN
    %nonassoc LET_BODY
    %right NOT
    %left '<' LE '='
    %left '+' '-'
    %left '*' '/'
    %right '~' ISVOID
    %left '@' '.'

    %%
    program : class_list
      { @$ = @1; ast_root = program($1); }
    ;

    class_list
      : class
        { $$ = single_Classes($1); parse_results = $$; }
      | class_list class
        { $$ = append_Classes($1, single_Classes($2)); parse_results = $$; }
    ;

    /* If no parent is specified, the class inherits from Object.  The error
       alternatives synchronize at the closing brace and semicolon so a bad
       class does not hide following classes. */
    class
      : CLASS TYPEID '{' dummy_feature_list '}' ';'
        { SET_NODELOC(@1); $$ = class_($2, idtable.add_string("Object"), $4,
                                      stringtable.add_string(curr_filename)); }
      | CLASS TYPEID INHERITS TYPEID '{' dummy_feature_list '}' ';'
        { SET_NODELOC(@1); $$ = class_($2, $4, $6,
                                      stringtable.add_string(curr_filename)); }
      | CLASS TYPEID '{' error '}' ';'
        { SET_NODELOC(@1); $$ = class_($2, idtable.add_string("Object"),
                                      nil_Features(), stringtable.add_string(curr_filename)); }
      | CLASS TYPEID INHERITS TYPEID '{' error '}' ';'
        { SET_NODELOC(@1); $$ = class_($2, $4, nil_Features(),
                                      stringtable.add_string(curr_filename)); }
      | CLASS error '{' error '}' ';'
        { SET_NODELOC(@1); $$ = class_(idtable.add_string("<error>"),
                                      idtable.add_string("Object"), nil_Features(),
                                      stringtable.add_string(curr_filename)); }
    ;

    dummy_feature_list
      : /* empty */ { $$ = nil_Features(); }
      | feature_list { $$ = $1; }
    ;

    feature_list
      : feature { $$ = single_Features($1); }
      | feature_list feature { $$ = append_Features($1, single_Features($2)); }
      | feature_list error ';' { $$ = $1; }
    ;

    feature
      : OBJECTID '(' formals ')' ':' TYPEID '{' expr '}' ';'
        { SET_NODELOC(@1); $$ = method($1, $3, $6, $8); }
      | OBJECTID ':' TYPEID ';'
        { SET_NODELOC(@1); $$ = attr($1, $3, no_expr()); }
      | OBJECTID ':' TYPEID ASSIGN expr ';'
        { SET_NODELOC(@1); $$ = attr($1, $3, $5); }
      /* A malformed feature is discarded by feature_list's error rule. */
    ;

    formals
      : /* empty */ { $$ = nil_Formals(); }
      | formal_list { $$ = $1; }
    ;

    formal_list
      : formal { $$ = single_Formals($1); }
      | formal_list ',' formal { $$ = append_Formals($1, single_Formals($3)); }
      | formal_list ',' error { $$ = $1; }
    ;

    formal
      : OBJECTID ':' TYPEID
        { SET_NODELOC(@1); $$ = formal($1, $3); }
    ;

    /* The precedence declarations above encode the precedence in the Cool
       reference manual.  The explicit %prec annotations make prefix forms
       bind as expected and let extends as far right as possible. */
    expr
      : OBJECTID ASSIGN expr
        { SET_NODELOC(@1); $$ = assign($1, $3); }
      | expr '@' TYPEID '.' OBJECTID '(' actuals ')'
        { SET_NODELOC(@1); $$ = static_dispatch($1, $3, $5, $7); }
      | expr '.' OBJECTID '(' actuals ')'
        { SET_NODELOC(@1); $$ = dispatch($1, $3, $5); }
      | OBJECTID '(' actuals ')'
        { SET_NODELOC(@1); $$ = dispatch(object(idtable.add_string("self")), $1, $3); }
      | IF expr THEN expr ELSE expr FI
        { SET_NODELOC(@1); $$ = cond($2, $4, $6); }
      | WHILE expr LOOP expr POOL
        { SET_NODELOC(@1); $$ = loop($2, $4); }
      | '{' expr_list '}'
        { SET_NODELOC(@1); $$ = block($2); }
      | LET let_bindings IN expr %prec LET_BODY
        { SET_NODELOC(@1); $$ = make_let($2, $4); }
      | CASE expr OF case_list ESAC
        { SET_NODELOC(@1); $$ = typcase($2, $4); }
      | NEW TYPEID
        { SET_NODELOC(@1); $$ = new_($2); }
      | ISVOID expr %prec ISVOID
        { SET_NODELOC(@1); $$ = isvoid($2); }
      | expr '+' expr
        { SET_NODELOC(@2); $$ = plus($1, $3); }
      | expr '-' expr
        { SET_NODELOC(@2); $$ = sub($1, $3); }
      | expr '*' expr
        { SET_NODELOC(@2); $$ = mul($1, $3); }
      | expr '/' expr
        { SET_NODELOC(@2); $$ = divide($1, $3); }
      | '~' expr
        { SET_NODELOC(@1); $$ = neg($2); }
      | expr '<' expr
        { SET_NODELOC(@2); $$ = lt($1, $3); }
      | expr '=' expr
        { SET_NODELOC(@2); $$ = eq($1, $3); }
      | expr LE expr
        { SET_NODELOC(@2); $$ = leq($1, $3); }
      | NOT expr
        { SET_NODELOC(@1); $$ = comp($2); }
      | '(' expr ')'
        { $$ = $2; }
      | INT_CONST
        { SET_NODELOC(@1); $$ = int_const($1); }
      | STR_CONST
        { SET_NODELOC(@1); $$ = string_const($1); }
      | BOOL_CONST
        { SET_NODELOC(@1); $$ = bool_const($1); }
      | OBJECTID
        { SET_NODELOC(@1); $$ = object($1); }
    ;

    actuals
      : /* empty */ { $$ = nil_Expressions(); }
      | expr_list_no_semi { $$ = $1; }
    ;

    let_bindings
      : let_binding { $$ = $1; }
      | let_bindings ',' let_binding
        { $1->next = $3; $$ = $1; }
    ;

    let_binding
      : OBJECTID ':' TYPEID
        { $$ = new LetBinding($1, $3, no_expr()); }
      | OBJECTID ':' TYPEID ASSIGN expr
        { $$ = new LetBinding($1, $3, $5); }
      | error
        { $$ = new LetBinding(idtable.add_string("<error>"),
                              idtable.add_string("Object"), no_expr()); }
    ;

    expr_list_no_semi
      : expr { $$ = single_Expressions($1); }
      | expr_list_no_semi ',' expr
        { $$ = append_Expressions($1, single_Expressions($3)); }
    ;

    expr_list
      : expr ';' { $$ = single_Expressions($1); }
      | expr_list expr ';' { $$ = append_Expressions($1, single_Expressions($2)); }
      | expr_list error ';' { $$ = append_Expressions($1, single_Expressions(no_expr())); }
    ;

    case_list
      : simple_case { $$ = single_Cases($1); }
      | case_list simple_case { $$ = append_Cases($1, single_Cases($2)); }
    ;

    simple_case
      : OBJECTID ':' TYPEID DARROW expr ';'
        { SET_NODELOC(@1); $$ = branch($1, $3, $5); }
    ;
    
    
    /* end of grammar */
    %%
    
    /* This function is called automatically when Bison detects a parse error. */
    void yyerror(char *s)
    {
      extern int curr_lineno;
      
      cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
      << s << " at or near ";
      print_cool_token(yychar);
      cerr << endl;
      omerrs++;
      
      if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
    }

