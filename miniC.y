%{
    #include <stdio.h>    
    #include <string.h>
    #include <stdlib.h>
    #include "listaSimbolos.h"
    #include "listaCodigo.h"

    

    extern char* outputFile;

    // Variables y funciones externas
    extern int yylex();
    extern int yylineno;
    void yyerror(const char *msg);
    void tryInsert(char* nombre, int tipo);
    void insertStr(char* _str);
    void tryUse(char* nombre);
    void tryUseID(char* nombre);
    char* selectFreeReg();
    void freeReg(char* _reg);
    void printData(FILE *output, ListaC listaCodigo);
    char* nuevaEtiqueta();
    void imprimirLC(ListaC codigo);
    void printOperacion(Operacion op);
    
    int noErrors();
    void genCode(ListaC decla, ListaC state_list);

    Lista listaSimbolos;
    ListaC listaCodigo;

    ListaC load(char* _arg, char* _op);
    ListaC save(ListaC _l1, char* _arg);
    ListaC neg(ListaC _l1);
    //ListaC operate(char* _arg1, char* _arg2, char* _op);
    ListaC operate(ListaC _l1, ListaC _l2, char* _op);
    ListaC condExpr(ListaC _l1, ListaC _l2, ListaC _l3);

    ListaC printString(int nStr);
    ListaC printExpr(ListaC _l1);
    ListaC readId(char* id);
    ListaC condIf(ListaC expr, ListaC state);
    ListaC condIfElse(ListaC expr, ListaC state1, ListaC state2);
    ListaC condWhile(ListaC expr, ListaC state);

    ListaC constAsig(char* id, ListaC expr);
    

    // Contador de cadenas de texto
    int str_cont = 0;

    // Contadores de error
    int semantic_errors = 0;
    extern int lexic_errors;

    // Array de uso de registros
    int regs[10] = {0,0,0,0,0,0,0,0,0,0};

    // Contador de etiquetas
    int cont_etiquetas = 1;


%}
%code requires{
#include "listaCodigo.h"
}

// Tipos de datos
/*
%union {
    int entero;
    char* cadena;
}
*/
%union {
    char *cadena;
    ListaC codigo;
}
%type <codigo> expression statement statement_list print_item print_list read_list declarations const_list


// Tokens

%token             VAR          "var"
%token             CONST        "const"         
%token             PRINT        "print"
%token             <cadena> ID           "id"
%token             INTLITERAL   "int"
%token             <cadena> INT          "num"
%token             LPAREN       "("
%token             RPAREN       ")"
%token             SEMICOLON    ";"
%token             COMMA        ","
%token             ASSIGNOP     "="
%token             PLUSOP       "+"
%token             MINUSOP      "-"
 //%token             REALLIT      "literall"
%token             LKEY         "{"
%token             RKEY         "}"
%token             COLON        ":"
%token             MULTOP       "*"
%token             DIVOP        "/"
%token             QUESTION     "?"
%token             IF           "if"
%token             ELSE         "else"
%token             WHILE        "while"
%token             READ         "read"
%token             <cadena> STRING       "string"


%define parse.error verbose

// Precedencias y asociatividad
%left "+" "-"
%left "*" "/"
%left UMINU
%expect 1

%%

/**************
//
//  GRAMATICA
//
***************/

program
    : preamble ID "(" ")" "{" declarations statement_list "}"  {
                                                                                    ListaC decls = (ListaC)$6;
                                                                                    ListaC stmts = (ListaC)$7;
                                                                                    genCode(decls, stmts);
                                                                                    liberaLS(listaSimbolos);
                                                                                    liberaLC(listaCodigo);
                                                                                }
    ;
preamble
    :/* vacío */ { 
        listaSimbolos = creaLS(); 
        listaCodigo = creaLC(); 
      }

declarations
    : declarations VAR tipo var_list  ";"               {$$=$1;}
    | declarations CONST tipo const_list ";"            {if(noErrors()){$$=$1;concatenaLC($$,$4);liberaLC($4);}}
    | /* empty */                                       {$$=creaLC();}
    | error ";"                                         {$$=creaLC();}
    ;

tipo
    : INTLITERAL                                        {}
    ;

var_list
    : ID                                                {tryInsert($1,1);}
    | var_list "," ID                                   {tryInsert($3,1);}
    ;
const_list  
    : ID "=" expression                                 {tryInsert($1,2); if(noErrors()){$$=constAsig($1,$3); freeReg(recuperaResLC($3));}}
    | const_list "," ID "=" expression                  {tryInsert($3,2); if(noErrors()){$$=$1; concatenaLC($$,constAsig($3,$5));freeReg(recuperaResLC($5));}}
    ;
statement_list
    : statement_list statement                          {
                                                            if(noErrors()){if ($2 != NULL) {
                                                                concatenaLC($1, $2);
                                                                liberaLC($2);
                                                            }
                                                            $$ = $1;}
                                                        }
    | /* empty */                                       {$$=creaLC();}
    ;

statement
    : ID "=" expression ";"                             {tryUse($1); if(noErrors()){$$=save($3,$1);}}//imprimirLC($3);
    | "{" statement_list "}"                            {if(noErrors){$$=$2;}}
    | IF "(" expression ")" statement ELSE statement    {if(noErrors()){$$=condIfElse($3,$5,$7);}}
    | IF "(" expression ")" statement                   {if(noErrors()){$$=condIf($3,$5);}}
    | WHILE "(" expression ")" statement                {if(noErrors()){$$=condWhile($3,$5);}}
    | PRINT "(" print_list ")" ";"                      {if(noErrors()){$$=$3;}}
    | READ "(" read_list ")" ";"                        {if(noErrors()){$$=$3;}}
    ;
print_list
    : print_item                                        {if(noErrors()){$$=$1;}}
    | print_list "," print_item                         {if(noErrors()){concatenaLC($1,$3); liberaLC($3); $$=$1;}}    
    ;

print_item
    : expression                                        {if(noErrors()){$$=printExpr($1);}}
    | STRING                                            {insertStr($1); if(noErrors()){$$=printString(str_cont);}}
    ;

read_list
    : ID                                                {tryUse($1); if(noErrors()){$$=readId($1);}}
    | read_list "," ID                                  {tryUse($3); if(noErrors()){concatenaLC($1,readId($3)); $$=$1;}}
    ;
expression
    : expression "+" expression                         {if(noErrors()){$$=operate($1,$3,"add");}}
    | expression "-" expression                         {if(noErrors()){$$=operate($1,$3,"sub");}}
    | expression "*" expression                         {if(noErrors()){$$=operate($1,$3,"mul");}}
    | expression "/" expression                         {if(noErrors()){$$=operate($1,$3,"div");}}
    | "(" expression "?" expression ":" expression ")"  {if(noErrors()){$$=condExpr($2,$4,$6);}}
    | "-" expression %prec UMINU                        {if(noErrors()){$$=neg($2);}}
    | "(" expression ")"                                {if(noErrors()){$$=$2;}}
    | ID                                                {tryUseID($1); if(noErrors()){$$=load($1,"lw");}}
    | INT                                               {if(noErrors()){$$=load($1,"li");}}
    ;



%%



void yyerror(const char *msg) {
    printf("[-] Error sintactico en linea %d: %s\n",yylineno,msg);
    semantic_errors++;
}

void tryInsert(char* nombre, int tipo) {
    PosicionLista p = buscaLS(listaSimbolos, nombre);
    if (p != finalLS(listaSimbolos) && strcmp(recuperaLS(listaSimbolos, p).nombre, nombre) == 0) {
        printf("[-] Error en linea %d: %s ya declarado.\n",yylineno,nombre);
        semantic_errors++;
    }
    else {
        Simbolo nodo = {nombre,tipo,0};
        insertaLS(listaSimbolos,finalLS(listaSimbolos), nodo);
    }
}

void tryUse(char* nombre) {
    PosicionLista p = buscaLS(listaSimbolos,nombre);
    if (p == finalLS(listaSimbolos) || strcmp(recuperaLS(listaSimbolos, p).nombre, nombre) != 0) {
        printf("[-] Error en linea %d: Variable %s no declarada. \n",yylineno, nombre);
        semantic_errors++;
    }
    else {
        if(recuperaLS(listaSimbolos,p).tipo==2) {
            printf("[-] Error en linea %d: Asignacion a constante %s.\n",yylineno, nombre);
            semantic_errors++;
        }
    }
}

void tryUseID(char* nombre) {
    PosicionLista p = buscaLS(listaSimbolos,nombre);
    if (p == finalLS(listaSimbolos) || strcmp(recuperaLS(listaSimbolos, p).nombre, nombre) != 0) {
        printf("[-] Error en linea %d: Variable %s no declarada. \n", yylineno, nombre);
        semantic_errors++;
    }
}

void insertStr(char* _str) {
    Simbolo nodo = {_str,3,str_cont};
    insertaLS(listaSimbolos,finalLS(listaSimbolos),nodo);
    str_cont++;
}


// Funcion para generar el codigo maquina
void genCode(ListaC decla, ListaC state_list) {
    if (lexic_errors > 0 || semantic_errors > 0) {
        printf("\n[-] Error: No se puede genear codigo. Corriga los errores y ejecute de nuevo.\n");
        return;
    }

    FILE *output = fopen(outputFile, "w");
    if (output == NULL) {
        printf("[-] Error: No se pudo abrir el fichero de salida.\n");
        return;
    }

    concatenaLC(decla,state_list);
    
    printData(output, decla);

    printf("[*] Compilacion realizada con exito\n");


    fclose(output);
}

void printData(FILE *output, ListaC listaCodigo) {

    //.data
    fprintf(output, "######################\n");
    fprintf(output, "# Seccion de datos.\n");
    fprintf(output, "   .data\n\n");

    PosicionLista i = inicioLS(listaSimbolos);
    while (i != finalLS(listaSimbolos)) {
        Simbolo s = recuperaLS(listaSimbolos,i);
        if(s.tipo==3) {
            fprintf(output," $str%d:\n",s.valor+1);
            fprintf(output,"        .asciiz %s\n",s.nombre);
        }
        i = siguienteLS(listaSimbolos,i);
    }
    i = inicioLS(listaSimbolos);
    while (i != finalLS(listaSimbolos)) {
        Simbolo s = recuperaLS(listaSimbolos,i);
        if(s.tipo!=3) {
            fprintf(output," _%s:\n",s.nombre);
            fprintf(output,"        .word 0\n");
        }
        i = siguienteLS(listaSimbolos,i);
    }

    // .text
    fprintf(output, "\n");
    fprintf(output, "######################\n");
    fprintf(output, "# Seccion de codigo.\n");
    fprintf(output, "   .text\n");
    fprintf(output, "   .globl main\n");   
    fprintf(output, " main:\n");   
    PosicionListaC p = inicioLC(listaCodigo);
    while (p != finalLC(listaCodigo)) {
        Operacion oper = recuperaLC(listaCodigo,p);
        if(strcmp(oper.op,"etiq")==0){
            fprintf(output," %s:",oper.res);
        }else{
            fprintf(output,"        %s",oper.op);
        if (oper.res) fprintf(output," %s",oper.res);
        if (oper.arg1) fprintf(output,",%s",oper.arg1);
        if (oper.arg2) fprintf(output,",%s",oper.arg2);
        }
        fprintf(output,"\n");
        p = siguienteLC(listaCodigo,p);
    }
    fprintf(output, "######################\n");
    fprintf(output, "### FIN\n");
    fprintf(output,"        li $v0, 10\n");
    fprintf(output,"        syscall");


}

char* selectFreeReg() {
    for (int i=0;i<10;i++) {
        if(regs[i]==0) {
            regs[i] = 1;
            char *aux;
            asprintf(&aux,"$t%d",i);
            //printf("[DEBUG] Register select: %d\n",i);  /* TODO - eliminar, depurado*/
            return aux;
        }
    }
    //printf("[DEBUG] No free registers aviable\n");  /* TODO - eliminar, depurado*/
    exit(1);
}

void freeReg(char* _reg) {
    int regIndex = _reg[2] - '0';
    if (regIndex < 0 || regIndex >= 10) {
        //printf("[-] Error: Register index out of bounds: %d\n", regIndex);      /* TODO - eliminar, depurado*/
        return;
    }
    if (regs[regIndex] == 0) {
        //printf("[-] Warning: Attempting to free an already free register: %s\n", _reg); /* TODO - eliminar, depurado*/
        return;
    }
    regs[regIndex] = 0;
    //printf("[DEBUG] Freed register: %s\n", _reg);   /* TODO - eliminar, depurado*/
}

ListaC load(char* _arg, char* _op) {
    ListaC result = creaLC();
    char* reg1 = selectFreeReg();
    char* arg;
    if(strcmp(_op, "lw") == 0){
        asprintf(&arg,"_%s",_arg);    // concatenar("_"+arg)
    } else{
        arg = _arg;
    }
    Operacion op = {_op,reg1,arg,NULL};
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/

    insertaLC(result,finalLC(result),op);
    guardaResLC(result,reg1);
    return result;
}

ListaC save(ListaC _l1, char* id){
    ListaC result = _l1;
    Operacion op;
    op.op = "sw";
    op.res = recuperaResLC(_l1);
    char* _id;
    asprintf(&_id,"_%s",id);
    op.arg1 = _id;
    op.arg2 = NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/
    insertaLC(result,finalLC(result),op);
    freeReg(op.res);

    return result;
}

/*  TODO si se va a usar cambiar el selecionar registro
ListaC operate(char* _arg1, char* _arg2, char* _op) {
    ListaC result = creaLC();
    int reg1 = selectFreeReg();
    char regName[10];
    sprintf(regName, "$t%d", reg1);
    Operacion op = {_op,regName,_arg1,_arg2};
    insertaLC(result,finalLC(result),op);
    guardaResLC(result,regName);
    freeReg(_arg1);
    freeReg(_arg2);
    return result;
}
*/
ListaC operate(ListaC _l1, ListaC _l2, char* _op) {
    ListaC result = _l1;
    concatenaLC(result,_l2);
    Operacion op;
    op.op = _op;
    op.res = recuperaResLC(_l1);
    op.arg1 = recuperaResLC(_l1);
    op.arg2 = recuperaResLC(_l2);
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/

    insertaLC(result,finalLC(result),op);
    liberaLC(_l2);
    freeReg(op.arg2);
    return result;
}

ListaC neg(ListaC _l1){
    ListaC result = _l1;
    Operacion op;
    op.op="neg";
    op.res=recuperaResLC(_l1);
    op.arg1=recuperaResLC(_l1);
    op.arg2=NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/

    insertaLC(result,finalLC(result),op);

    return result;
}

void printOperacion(Operacion op) {
    printf("Operacion: %s, Arg1: %s,RESULT = %s\n",op.op,op.arg1,op.res);
}

char* nuevaEtiqueta(){
    char *aux;
    asprintf(&aux,"$l%d",cont_etiquetas++);
    return aux;
}

void imprimirLC(ListaC codigo) {
    PosicionListaC p = inicioLC(codigo);
    while (p != finalLC(codigo)) {
        Operacion oper = recuperaLC(codigo,p);
        printf("%s",oper.op);
        if (oper.res) printf(" %s",oper.res);
        if (oper.arg1) printf(",%s",oper.arg1);
        if (oper.arg2) printf(",%s",oper.arg2);
        printf("\n");
        p = siguienteLC(codigo,p);
    }
}

ListaC condExpr(ListaC _l1, ListaC _l2, ListaC _l3){
    ListaC result = _l1;
    Operacion op;

    char* l1 = nuevaEtiqueta();
    char* l2 = nuevaEtiqueta();

    char* t0 = recuperaResLC(_l1);
    char* t1 = recuperaResLC(_l2);
    char* t2 = recuperaResLC(_l3);

    // beqz $l1
    op.op = "beqz";
    op.res = t0;
    op.arg1 = l1;
    op.arg2 = NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/
    insertaLC(result,finalLC(result),op);

    concatenaLC(result,_l2);

    // move $t0, $t1
    op.op = "move";
    op.res = t0;
    op.arg1 = t1;
    op.arg2 = NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/
    insertaLC(result,finalLC(result),op);

    // b $l2
    op.op = "b";
    op.res = l2;
    op.arg1 = NULL;
    op.arg2 = NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/
    insertaLC(result,finalLC(result),op);

    // etiqueta l1
    op.op = "etiq";
    op.res = l1;
    op.arg1 = NULL;
    op.arg2 = NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/
    insertaLC(result,finalLC(result),op);

    concatenaLC(result,_l3);

    // move $t0, $t2
    op.op = "move";
    op.res = t0;
    op.arg1 = t2;
    op.arg2 = NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/
    insertaLC(result,finalLC(result),op);

    // etiqueta l2
    op.op = "etiq";
    op.res = l2;
    op.arg1 = NULL;
    op.arg2 = NULL;
    //printf("%s %s %s %s\n",op.op,op.res,op.arg1,op.arg2);   /* TODO - eliminar, depurado*/
    insertaLC(result,finalLC(result),op);

    //printf("t0= %s,t1=%s,t2=%s\n",t0,t1,t2);                /* TODO - eliminar, depurado*/

    guardaResLC(result,t0);
    freeReg(t1);
    freeReg(t2);

    return result;
}

ListaC printString(int nStr){
    ListaC result = creaLC();
    Operacion op; op.arg2=NULL;

    op.op = "li";
    op.res = "$v0";
    op.arg1 = "4";
    insertaLC(result,finalLC(result),op);

    op.op = "la";
    op.res = "$a0";
    char *rStr;
    asprintf(&rStr,"$str%d",nStr);
    op.arg1 = rStr;
    insertaLC(result,finalLC(result),op);

    op.op = "syscall";
    op.res = NULL;
    op.arg1 = NULL;
    insertaLC(result,finalLC(result),op);

    return result;
}

ListaC printExpr(ListaC _l1){
    ListaC result = _l1;
    Operacion op; op.arg2 = NULL;

    op.op = "li";
    op.res = "$v0";
    op.arg1 = "1";
    insertaLC(result,finalLC(result),op);
  
    op.op = "move";
    op.res = "$a0";
    op.arg1 = recuperaResLC(_l1);
    insertaLC(result,finalLC(result),op);

    op.op = "syscall";
    op.res = NULL;
    op.arg1 = NULL;
    insertaLC(result,finalLC(result),op);

    freeReg(recuperaResLC(_l1));

    return result;
}

ListaC readId(char* id){
    ListaC result = creaLC();
    Operacion op; op.arg2=NULL;

    op.op = "li";
    op.res = "$v0";
    op.arg1 = "5";
    insertaLC(result,finalLC(result),op);

    op.op = "syscall";
    op.res = NULL;
    op.arg1 = NULL;
    insertaLC(result,finalLC(result),op);

    op.op = "sw";
    op.res = "$v0";
    char *rId;
    asprintf(&rId,"_%s",id);
    op.arg1 = rId;
    insertaLC(result,finalLC(result),op);

    return result;

}

ListaC condIf(ListaC expr, ListaC state){
    ListaC result = expr;

    char* l1 = nuevaEtiqueta();
    Operacion op; op.arg2 = NULL;

    // beqz
    op.op = "beqz";
    op.res = recuperaResLC(expr);
    op.arg1 = l1;
    insertaLC(result,finalLC(result),op);
    
    concatenaLC(result,state);
    // etiqueta l1
    op.op = "etiq";
    op.res = l1;
    op.arg1 = NULL;
    op.arg2 = NULL;
    insertaLC(result,finalLC(result),op);

    freeReg(recuperaResLC(expr));

    return result;
}

ListaC condIfElse(ListaC expr, ListaC state1, ListaC state2){
    ListaC result = expr;
    Operacion op; op.arg2 = NULL;

    char* l1 = nuevaEtiqueta();
    char* l2 = nuevaEtiqueta();

    // beqz
    op.op = "beqz";
    op.res = recuperaResLC(expr);
    op.arg1 = l1;
    insertaLC(result,finalLC(result),op);

    concatenaLC(result,state1);

    //b
    op.op = "b";
    op.res = l2;
    op.arg1 = NULL;
    insertaLC(result,finalLC(result),op);

    // etiqueta l1
    op.op = "etiq";
    op.res = l1;
    op.arg1 = NULL;
    op.arg2 = NULL;
    insertaLC(result,finalLC(result),op);

    concatenaLC(result,state2);

    // etiqueta l2
    op.op = "etiq";
    op.res = l2;
    op.arg1 = NULL;
    op.arg2 = NULL;
    insertaLC(result,finalLC(result),op);

    freeReg(recuperaResLC(expr));
    return result;
}

ListaC condWhile(ListaC expr, ListaC state){
    ListaC result = expr;
    Operacion op; op.arg2 = NULL;

    char* l1 = nuevaEtiqueta();
    char* l2 = nuevaEtiqueta();

    // etiqueta l1
    op.op = "etiq";
    op.res = l1;
    op.arg1 = NULL;
    op.arg2 = NULL;
    insertaLC(result,inicioLC(result),op);

    // beqz
    op.op = "beqz";
    op.res = recuperaResLC(expr);
    op.arg1 = l2;
    insertaLC(result,finalLC(result),op);

    concatenaLC(result,state);

    //b
    op.op = "b";
    op.res = l1;
    op.arg1 = NULL;
    insertaLC(result,finalLC(result),op);

    // etiqueta l2
    op.op = "etiq";
    op.res = l2;
    op.arg1 = NULL;
    op.arg2 = NULL;
    insertaLC(result,finalLC(result),op);

    freeReg(recuperaResLC(expr));
    return result;
}
 
ListaC constAsig(char* id, ListaC expr){
    ListaC result = expr;
    Operacion op; op.arg2 = NULL;

    char* _id;
    asprintf(&_id,"_%s",id);

    op.op = "sw";
    op.res = recuperaResLC(expr);
    op.arg1 = _id;
    insertaLC(result,finalLC(result),op);

    return result;
}

int noErrors(){
    return semantic_errors==0 && lexic_errors==0;
}