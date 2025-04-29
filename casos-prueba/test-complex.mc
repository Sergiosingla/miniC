main() {
    var int a, b, c, resultado, x;
    const int limite = 10, incremento = 2;
    var int cont;

    read(a, b);
    print("Valores iniciales:", a," ", b,"\n");

    c = (a ? a - b : b - a);  // expresión ternaria
    print("Diferencia:", c,"\n");

    if (c) {
        resultado = 0;
        cont = 10;
        while (cont) {
            resultado = resultado + incremento;
            cont = cont - 1;
        }
        print("Resultado acumulado:", resultado, "\n");
    } else {
        print("No hay diferencia.\n");
    }

    x = a + b + resultado;
    print("Suma total:", x,"\n");

    if(c){
        resultado = resultado * 2;
        print("Resultado acumulado duplicado:", resultado,"\n");
    }
}
