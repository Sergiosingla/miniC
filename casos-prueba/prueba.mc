prueba() {
    const int a = 1, b = 0, p = 10;
    var int c, d;
    print("Inicio del programa\n");
    d = 50;
    c = (a ? d : p);
    while (c) {
        print("c = ", c, "\n");
        c = c - 2 + 1;
    }
    print("D = ", d, "\n");
    print("Final", "\n");
}