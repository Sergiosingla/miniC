miniC: lex.yy.c main.c miniC.tab.c listaSimbolos.c listaCodigo.c
	gcc main.c lex.yy.c miniC.tab.c listaSimbolos.c listaCodigo.c -lfl -o miniC

lex.yy.c: miniC.l
	flex miniC.l

miniC.tab.h miniC.tab.c : miniC.y listaSimbolos.h listaCodigo.h
	bison -d -v miniC.y

clean:
	rm -f miniC lex.yy.c miniC.tab.* out.s
