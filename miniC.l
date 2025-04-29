%{
#include "miniC.tab.h"
#include "listaCodigo.h"

// Declaracion de funciones auxiliares
int valid_int(char* str);

int lexic_errors = 0;

%}
%option yylineno
digito              [0-9]
letra               [a-zA-Z]
entero              {digito}+  
escape              (\\\"|\\\\|\\.)
notallow            [^a-zA-Z0-9_,;:=*?/\-+$(){}? \n\t\r]    


%x COMENT

%%

 // Tambien puedo usar la ER para extraer el comentario multilinea
"/*"						                    {BEGIN COMENT; yymore();}
<COMENT>"*"+"/"					                {BEGIN INITIAL; /*printf("[+]Comment: %s\n",yytext);*/}
<COMENT>[^*]*						            yymore();
<COMENT>[*]+[^*/]*                              yymore();
<COMENT><<EOF>>                                 {printf("[-]Error lexico en linea %d: Comentario no cerrado.\n",yylineno);lexic_errors++;}
[ \n\t\r]+                                    	;
"//"(.*)[\n]                                	;//printf("[+]Comment: %s", yytext);

 /* Ejercicio 2 sesion 2 */
\"([^"\n]|{escape})*\"                          {yylval.cadena = strdup(yytext);return STRING;}
print                                       	return PRINT;
const                                           return CONST;
var                                             return VAR;
if                                              return IF;
else                                            return ELSE;
while                                           return WHILE;
read                                            return READ;
int                                             return INTLITERAL;
({letra}|_|"$")({letra}|{digito}|_|"$")*    	{   yylval.cadena = strdup(yytext);     //TODO chekear si $ es valido
                                                    if(strlen(yylval.cadena) > 16) {
                                                        printf("[-] Error lexico en linea %d: Identificador demasiado largo (id<=16 caracteres).\n",yylineno);
                                                        lexic_errors++;
                                                    }
                                                    else {return ID;}};                       
"("                                         	return LPAREN;		
")"                                         	return RPAREN;
"{"                                         	return LKEY;
"}"                                         	return RKEY;
";"                                         	return SEMICOLON;
","                                        	    return COMMA;
":"                                             return COLON;
"="                                         	return ASSIGNOP;
"+"                                         	return PLUSOP;
"-"                                         	return MINUSOP;
"*"                                             return MULTOP;
"?"                                             return QUESTION;
{entero}                                        {if (valid_int(yytext)) {
                                                    printf("[-] Error lexico en linea %d: Número superior al MAX-INT\n",yylineno);
                                                    lexic_errors++;
                                                    }
                                                    else{yylval.cadena = strdup(yytext);return INT;}
                                                }
{notallow}                                      {printf("[-]Error lexico en linea %d, en carácter: %s\n", yylineno,yytext); lexic_errors++;}      //TODO compltar modo panico
%%

int valid_int(char* str) {
    long long max_int = 2147483648;

    long long num = atoll(str);
    if(num > max_int) {
        return 1;
    }
    return 0;
}


