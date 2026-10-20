%option noyywrap

%{
#include <iostream>
#include <fstream>
#include <string>

#include"symbol_info.h"

#define YYSTYPE symbol_info*

#include "22201358_22299105.tab.h"

extern YYSTYPE yylval;

using namespace std;

void yyerror(const char *s);

string loglist;

extern int line_num;

extern ofstream outlog;

%}

/* Regular Definitions */

delim	 [ \t\v\r]

/* write regular expressions for whitespace and newline */
ws		 {delim}+

newline  \n

letter_	 [A-Za-z_]
digit	 [0-9]

/* write regular expressions for id, float and integers */
id	         {letter_}({letter_}|{digit})*
float_const  {digit}+\.{digit}*([Ee][+-]?{digit}+)?|{digit}+[Ee][+-]?{digit}+|\.{digit}+([Ee][+-]?{digit}+)?
int_const    {digit}+	 


%%

{ws}		{ /* ignore whitespace */ }
{newline}	{  line_num++; }


"if"          { 
                loglist="Line no "+to_string(line_num)+": Token <IF> Lexeme "+(string)yytext+" found"+"\n"+"\n";
			    outlog<<loglist;
                return IF; }

"else"       {
                loglist="Line no "+to_string(line_num)+": Token <ELSE> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return ELSE;
            }   

"for"        {
                loglist="Line no "+to_string(line_num)+": Token <FOR> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return FOR;
            }                       

"while"       { 
                loglist="Line no "+to_string(line_num)+": Token <WHILE> Lexeme "+(string)yytext+" found"+"\n"+"\n";
			    outlog<<loglist; 
                return WHILE; }

"float"       {
                loglist="Line no "+to_string(line_num)+": Token <FLOAT> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return FLOAT;
            }          

"char"        {
                loglist="Line no "+to_string(line_num)+": Token <CHAR> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return CHAR;
            }  

"do"        {
                loglist="Line no "+to_string(line_num)+": Token <DO> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return DO;
            }

"break"     {
                loglist="Line no "+to_string(line_num)+": Token <BREAK> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return BREAK;
            }

"int"       {
                loglist="Line no "+to_string(line_num)+": Token <INT> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return INT;
            }

"double"    {
                loglist="Line no "+to_string(line_num)+": Token <DOUBLE> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return DOUBLE;
            }

"void"      {
                loglist="Line no "+to_string(line_num)+": Token <VOID> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return VOID;
            }

"return"    {
                loglist="Line no "+to_string(line_num)+": Token <RETURN> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return RETURN;
            }

"switch"    {
                loglist="Line no "+to_string(line_num)+": Token <SWITCH> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return SWITCH;
            }

"case"      {
                loglist="Line no "+to_string(line_num)+": Token <CASE> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return CASE;
            }

"default"   {
                loglist="Line no "+to_string(line_num)+": Token <DEFAULT> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return DEFAULT;
            }

"continue"  {
                loglist="Line no "+to_string(line_num)+": Token <CONTINUE> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return CONTINUE;
            }

"goto"      {
                loglist="Line no "+to_string(line_num)+": Token <GOTO> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return GOTO;
            }

"printf"    {
                loglist="Line no "+to_string(line_num)+": Token <PRINTLN> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return PRINTLN;
            }


{id}       {
                symbol_info *s = new symbol_info((string)yytext,"ID");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_num)+": Token <ID> Lexeme "+(string)yytext+" found"+"\n"+"\n";
			    outlog<<loglist;
                return ID;
            }

{int_const} {
                symbol_info *s = new symbol_info((string)yytext,"CONST_INT");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_num)+": Token <CONST_INT> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return CONST_INT;
            }

{float_const} {
                symbol_info *s = new symbol_info((string)yytext,"CONST_FLOAT");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_num)+": Token <CONST_FLOAT> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return CONST_FLOAT;
            }           

"++" {
    symbol_info *s = new symbol_info((string)yytext,"INCOP");
    yylval = (YYSTYPE)s;
    loglist="Line no "+to_string(line_num)+": Token <INCOP> Lexeme "+(string)yytext+" found"+"\n"+"\n";
    outlog<<loglist;
    return INCOP;
}

"--" {
    symbol_info *s = new symbol_info((string)yytext,"DECOP");
    yylval = (YYSTYPE)s;
    loglist="Line no "+to_string(line_num)+": Token <DECOP> Lexeme "+(string)yytext+" found"+"\n"+"\n";
    outlog<<loglist;
    return DECOP;
}

"<"|">"|"<="|">="|"=="|"!=" {
                symbol_info *s = new symbol_info((string)yytext, "RELOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_num)+": Token <RELOP> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return RELOP;
           }

"=" {
                loglist="Line no "+to_string(line_num)+": Token <ASSIGNOP> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return ASSIGNOP;
           }

"&&"|"||" {
                symbol_info *s = new symbol_info((string)yytext, "LOGICOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_num)+": Token <LOGICOP> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return LOGICOP;
           }

"!" {
                loglist="Line no "+to_string(line_num)+": Token <NOT> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return NOT;
           }

"*"|"/"|"%" {
                symbol_info *s = new symbol_info((string)yytext,"MULOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_num)+": Token <MULOP> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return MULOP;
           }

"(" {
                loglist="Line no "+to_string(line_num)+": Token <LPAREN> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return LPAREN;
           }

")" {
                loglist="Line no "+to_string(line_num)+": Token <RPAREN> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return RPAREN;
           }

"{" {
                loglist="Line no "+to_string(line_num)+": Token <LCURL> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return LCURL;
           }

"}" {
                loglist="Line no "+to_string(line_num)+": Token <RCURL> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return RCURL;
           }

"[" {
                loglist="Line no "+to_string(line_num)+": Token <LTHIRD> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return LTHIRD;
           }

"]" {
                loglist="Line no "+to_string(line_num)+": Token <RTHIRD> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;
                return RTHIRD;
           }


":" { 
                loglist="Line no "+to_string(line_num)+": Token <COLON> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;               
                return COLON;
           }

";" { 
                loglist="Line no "+to_string(line_num)+": Token <SEMICOLON> Lexeme "+(string)yytext+" found"+"\n"+"\n";
                outlog<<loglist;               
                return SEMICOLON;
           }

"+"|"-"	    {
                symbol_info *s = new symbol_info((string)yytext,"ADDOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_num)+": Token <ADDOP> Lexeme "+(string)yytext+" found"+"\n"+"\n";
			    outlog<<loglist;
                return ADDOP;
		    }

","        { 
                loglist="Line no "+to_string(line_num)+": Token <COMMA> Lexeme "+(string)yytext+" found"+"\n"+"\n";
			    outlog<<loglist;               
                return COMMA; }

.           {
                loglist="Line no "+to_string(line_num)+": Invalid token Lexeme "+(string)yytext+" found!"+"\n"+"\n";
                outlog<<loglist;
            }                
%%