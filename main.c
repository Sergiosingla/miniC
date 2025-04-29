#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "miniC.tab.h"

extern char *yytext;
extern int  yyleng;
extern int yylex();
FILE *fich;
extern FILE *yyin;
extern int yyparse();

char* outputFile = "out.s";


int main(int argc, char const *argv[])
{
    if(argc != 2 && argc !=3) {
        printf("Uso %s fichero (salida)\n",argv[0]);
        exit(1);
    }

    if(argc == 3){
        strncpy(outputFile, argv[2], sizeof(outputFile) - 1);
        outputFile[sizeof(outputFile) - 1] = '\0';
    }

    FILE *fich = fopen(argv[1], "r");
    if(fich==NULL){
        printf("Error abriendo %s\n",argv[1]);
        exit(2);
    }

    yyin = fich;
    yyparse();

    fclose(fich);
}
