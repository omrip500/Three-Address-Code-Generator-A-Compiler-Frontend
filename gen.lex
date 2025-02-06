%{
/* gen.tab.h was generated by bison with the -d option */
#include <stdlib.h>
#include "gen.tab.h"
;
%}

%option noyywrap
%option yylineno

%x COMMENT

%%

"while"    { return WHILE; }
"if"       { return IF; }
"else"     { return ELSE; }

"read"    { return READ; }
"write"   { return WRITE; }

"int"       { return INT; }
"double"    { return DOUBLE; }  

"repeat"    { return REPEAT; }

[0-9]+         { yylval.ival = atoi (yytext); return INT_NUM; }
[0-9]+\.[0-9]+ { yylval.dval = atof (yytext); return DOUBLE_NUM; }

[a-zA-Z_]+  { strcpy(yylval.name, yytext); return ID; }


"+"        { yylval.op = PLUS; return ADDOP;}
"-"        { yylval.op = MINUS; return ADDOP;}

"*"        { yylval.op = MUL; return MULOP; }
"/"        { yylval.op = DIV; return MULOP;}

"<"        {  yylval.relop = "<"; return RELOP; }
">"        {  yylval.relop = ">"; return RELOP; }
"<="       {  yylval.relop = "<="; return RELOP; }
">="       {  yylval.relop = ">="; return RELOP; }
"=="       {  yylval.relop = "=="; return RELOP; }
"!="       {  yylval.relop = "!="; return RELOP; }

[=;,(){}:]       { return yytext[0]; }

[\n\r\t ]+   { /* skip white space */ }

"//".*     /* skip comment */

"/*"           { BEGIN(COMMENT); }
<COMMENT>.|\n     { /* skip character in comment */ }
<COMMENT>"*/"  { BEGIN(0); }

.          { errorMsg("unrecognized token %c(%x)\n", 
                                yytext[0], yytext[0]); }

%%
