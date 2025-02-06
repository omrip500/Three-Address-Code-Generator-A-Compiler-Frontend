%code {
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <assert.h>
#include "symboltable.h"

typedef int TEMP;  /* temporary variable.
                       temporary variables are named t1, t2, ... 
                       in the generated code but
					   inside the compiler they may be represented as
					   integers. For example,  temporary 
					   variable 't3' is represented as 3.
					*/
  
// number of errors found by the compiler 
int errors = 0;					

extern int yylex (void);
void yyerror (const char *s);

static int newtemp(), newlabel();
void emit (const char *format, ...);
void emitlabel (int label);


enum type currentType;  // type specified in current declaration

} // %code

%code requires {
    void errorMsg (const char *format, ...);
    enum {NSIZE = 100}; // max size of variable names
    enum type {_INT, _DOUBLE };
	  enum op { PLUS, MINUS, MUL, DIV, PLUS_PLUS, MINUS_MINUS };
	
	typedef int LABEL;  /* symbolic label. Symbolic labels are named
                       L_1, L_2, ... in the generated code 
					   but inside the compiler they may be represented as
					   integers. For example,  symbolic label 'L_3' 
					   is represented as 3.
					 */
    struct exp { /* semantic value for expression */
	    char result[NSIZE]; /* result of expression is stored 
   		   in this variable. If result is a constant number
		   then the number is stored here (as a string) */
	    enum type type;     // type of expression
	};

	
} // code requires

/* this will be the type of all semantic values. 
   yylval will also have this type 
*/
%union {
   char name[NSIZE];
   int ival;
   double dval;
   enum op op;
   struct exp e;
   LABEL label;
   const char *relop;
   enum type type;
   struct { LABEL start_repeat_label, exit_repeat_label; } repeatLabels;
}

%token <ival> INT_NUM
%token <dval> DOUBLE_NUM
%token <relop> RELOP
%token <name> ID
%token <op> ADDOP MULOP 

%token REPEAT
%token WHILE IF ELSE 
%token INT DOUBLE READ WRITE

%nterm <e> expression
%nterm <label> boolexp  start_label exit_label
%nterm <type> type
%nterm <repeatLabels> dummy_stmt;

/* this tells bison to generate better error messages
   when syntax errors are encountered (these error messages
   are passed as an argument to yyerror())
*/
%define parse.error verbose

/* if you are using an old version of bison use this instead:
%error-verbose */

/* enable trace option (for debugging). 
   To request trace info: assign non zero value to yydebug */
%define parse.trace
/* formatting semantic values (when tracing): */
%printer {fprintf(yyo, "%s", $$); } ID
%printer {fprintf(yyo, "%d", $$); } INT_NUM
%printer {fprintf(yyo, "%f", $$); } DOUBLE_NUM

%printer {fprintf(yyo, "result=%s, type=%s",
            $$.result, $$.type == _INT ? "int" : "double");} expression


/* token ADDOP has lower precedence than token MULOP.
   Both tokens have left associativity.

   This solves the shift/reduce conflicts in the grammar 
   because of the productions:  
      expression: expression ADDOP expression | expression MULOP expression   
*/
%left ADDOP
%left MULOP

%%
program: declarations
         stmtlist;

declarations: declarations decl;

declarations: %empty;

decl:  type {currentType = $1;} idlist ';'

type: INT    { $$= _INT;} |
      DOUBLE { $$ = _DOUBLE; };
	  
idlist:  idlist ',' ID
{
  if(putSymbol($3, currentType) == NULL)
  {
      errorMsg("variable %s already declared\n", $3);
      exit(1);
  }
};

idlist:  ID
{
  if(putSymbol($1, currentType) == NULL)
  {
      errorMsg("variable %s already declared\n", $1);
      exit(1);
  }
};
			
stmt: assign_stmt  |
      while_stmt   |
	  if_stmt      |
	  repeat_stmt  |
	  read_stmt    |
	  write_stmt   |
	  block_stmt
	  ;

assign_stmt:  ID '=' expression ';'
{ 
  if (lookup($1) == NULL)
  {
      errorMsg("variable %s not declared\n", $1);
      exit(1);
  }

  else
  {
    if (lookup($1)->type != $3.type)
    {
      emit("%s = %s(%s)\n", $1, lookup($1)->type == _INT ? "int" : "double", $3.result);
    }

    else
    {
        emit("%s = %s\n", $1, $3.result);
    }
  }
};


expression : expression ADDOP expression
{ 
  if ($1.type == _DOUBLE && $3.type == _INT)
  {
      int newTemp = newtemp();
      sprintf($$.result, "t%d", newtemp());
      $$.type = _DOUBLE;
      emit("t%d = double(%s)\n", newTemp, $3.result);
      emit("%s = %s (%c) t%d\n", $$.result, $1.result, ($2 == PLUS ? '+' : '-'), newTemp);  

     
  } else if ($1.type == _INT && $3.type == _DOUBLE) {
      int newTemp = newtemp();
      sprintf($$.result, "t%d", newtemp());
      $$.type = _DOUBLE;
      emit("t%d = double(%s)\n", newTemp, $1.result);
      emit("%s = t%d (%c) %s\n", $$.result, newTemp, ($2 == PLUS ? '+' : '-'), $3.result);
  }

  else if($1.type == _INT && $3.type == _INT)
  {
      sprintf($$.result, "t%d", newtemp());
      $$.type = _INT;
      emit("%s = %s %c %s\n", $$.result, $1.result, ($2 == PLUS ? '+' : '-'), $3.result);
  }

  else
  {
      sprintf($$.result, "t%d", newtemp());
      $$.type = _DOUBLE;
      emit("%s = %s (%c) %s\n", $$.result, $1.result, ($2 == PLUS ? '+' : '-'), $3.result);
  }

};

expression : expression MULOP expression
{ 
  if($1.type == _DOUBLE && $3.type == _INT)
  {
      int newTemp = newtemp();
      sprintf($$.result, "t%d", newtemp());
      $$.type = _DOUBLE;
      emit("t%d = double(%s)\n", newTemp, $3.result);
      emit("%s = %s (%c) t%d\n", $$.result, $1.result, ($2 == MUL ? '*' : '/'), newTemp);  
  }

  else if($1.type == _INT && $3.type == _DOUBLE)
  {
      int newTemp = newtemp();
      sprintf($$.result, "t%d", newtemp());
      $$.type = _DOUBLE;
      emit("t%d = double(%s)\n", newTemp, $1.result);
      emit("%s = t%d (%c) %s\n", $$.result, newTemp, ($2 == MUL ? '*' : '/'), $3.result);
  }

  else if($1.type == _INT && $3.type == _INT)
  {
      sprintf($$.result, "t%d", newtemp());
      $$.type = _INT;
      emit("%s = %s %c %s\n", $$.result, $1.result, ($2 == MUL ? '*' : '/'), $3.result);
  }

  else
  {
      sprintf($$.result, "t%d", newtemp());
      $$.type = _DOUBLE;
      emit("%s = %s (%c) %s\n", $$.result, $1.result, ($2 == MUL ? '*' : '/'), $3.result);
  }
};   
                  
expression :  '(' expression ')' { $$ = $2; }
           |  ID 
              { 
                if(lookup($1) == NULL) 
                {
                  errorMsg("variable %s not declared\n", $1);
                  exit(1);
                }
                else                
                  strcpy($$.result, $1); $$.type = lookup($1)->type; 
              }                 
           |  INT_NUM    { sprintf($$.result, "%d", $1); $$.type = _INT; }
           |  DOUBLE_NUM { sprintf($$.result, "%.2f", $1); $$.type = _DOUBLE; }
           ;

while_stmt: WHILE start_label '('  boolexp  ')' 
			stmt 
                      { emit("goto L_%d\n", $2);
                        emitlabel($4);
					  };
						 
start_label: %empty { $$ = newlabel(); emitlabel($$); };

boolexp:  expression RELOP expression 
             {  $$ = newlabel();
			    emit("ifFalse %s %s %s goto L_%d\n", 
			          $1.result, $2, $3.result, $$);
             };

if_stmt:  IF exit_label '(' boolexp ')' stmt
               { emit("goto L_%d\n", $2);
                 emitlabel($4);
               }				 
          ELSE stmt { emitlabel($2); };
		  
exit_label: %empty { $$ = newlabel(); };

repeat_stmt  : dummy_stmt REPEAT '(' expression ')'
{
    if($4.type == _DOUBLE)
    {
        errorMsg("repeat condition must be an integer\n");
        exit(1);
    }

    emitlabel($1.start_repeat_label);
    emit("ifFalse %s > 0 goto L_%d\n", $4.result, $1.exit_repeat_label);
}
  stmt
  {
    emit("%s = %s - 1\n", $4.result, $4.result);
    emit("ifFalse %s > 0 goto L_%d\n", $4.result, $1.exit_repeat_label);
    emit("goto L_%d\n", $1.start_repeat_label);
    emitlabel($1.exit_repeat_label);
  };


read_stmt: READ '(' ID ')' ';' 
{
  if(lookup($3)->type == _INT)
  {
      emit("in %s\n", $3);
  }
  else
  {
      emit("(in) %s\n", $3);
  }
};
             
write_stmt: WRITE '(' expression ')' ';' 
{
  if($3.type == _INT)
  {
      emit("out %s\n", $3.result);
  }
  else
  {
      emit("(out) %s\n", $3.result);
  }
};
                
block_stmt:   '{'  stmtlist '}';

stmtlist: stmtlist stmt { emit("\n"); }
        | %empty
		;

dummy_stmt: %empty { $$.start_repeat_label = newlabel();
                     $$.exit_repeat_label = newlabel();
                   };
					 
%%
int main (int argc, char **argv)
{
  extern FILE *yyin; /* defined by flex */
  extern int yydebug;
  
  if (argc > 2) {
     fprintf (stderr, "Usage: %s [input-file-name]\n", argv[0]);
	 return 1;
  }
  if (argc == 2) {
      yyin = fopen (argv [1], "r");
      if (yyin == NULL) {
          fprintf (stderr, "failed to open %s\n", argv[1]);
	      return 2;
	  }
  } // else: yyin will be the standard input (this is flex's default)
  

  yydebug = 0; //  should be set to 1 to activate the trace

  if (yydebug)
      setbuf(stdout, NULL); // (for debugging) output to stdout will be unbuffered
  
  yyparse();
  
  fclose (yyin);
  return 0;
} /* main */

/* called by yyparse() whenever a syntax error is detected */
void yyerror (const char *s)
{
  extern int yylineno; // defined by flex
  
  fprintf (stderr,"line %d:%s\n", yylineno,s);
}

/* temporary variables are represented by numbers. 
   For example, 3 means t3
*/
static
TEMP newtemp ()
{
   static int counter = 1;
   return counter++;
} 


// labels are represented by numbers. For example, 3 means L_3
static
LABEL newlabel ()
{
   static int counter = 1;
   return counter++;
} 

// emit works just like  printf  --  we use emit 
// to generate code and print it to the standard output.
void emit (const char *format, ...)
{
  /* uncomment following line to stop generating code when errors
	   are detected */
    /* if (errors > 0) return; */ 
    printf ("    ");  // this is meant to add a nice indentation.
                      // Use emitlabel() to print a label without the indentation.    
    va_list argptr;
	va_start (argptr, format);
	// all the arguments following 'format' are passed on to vprintf
	vprintf (format, argptr); 
	va_end (argptr);
}

/* use this  to emit a label without any indentation */
void emitlabel(LABEL label) 
{
    /* uncomment following line to stop generating code when errors
	   are detected */
    /* if (errors > 0) return; */ 
	
    printf ("L_%d:\n",  label);
}

/*  Use this to print error messages to standard error.
    The arguments to this function are the same as printf's arguments
*/
void errorMsg(const char *format, ...)
{
    extern int yylineno; // defined by flex
	
	fprintf(stderr, "line %d: ", yylineno);
	
    va_list argptr;
	va_start (argptr, format);
	// all the arguments following 'format' are passed on to vfprintf
	vfprintf (stderr, format, argptr); 
	va_end (argptr);
	
	errors++;
} 
    






