# Manual de usuario

Para descargar el programa (si no lo tienes ya descargado) puedes clonar el repositorio de github (https://github.com/Sergiosingla/miniC).  
Una vez descargado ejecutar en una terminal `make`, para compilar y generar el ejecutable.

Al hacer `make`, se generará un ejecutable llamado “miniC”.  
Ya se puede ejecutar y compilar programas del lenguaje miniC, para ello su uso es el siguiente:  
`./miniC [fichero a compilar] [(opcional) fichero de salida del código máquina]`

Si no se pasa un fichero para la salida el programa volcara la salida del código máquina en un fichero llamado “out.s”, ese ya es código que se puede pasar a mips para ejecutar en ensamblador.
