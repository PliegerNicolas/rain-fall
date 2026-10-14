/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

/* Function: run. Address: 08048444 */

// void run(void)

// {
//   fwrite("Good... Wait what?\n",1,0x13,stdout);
//   system("/bin/sh");
//   return;
// }


/* Function: main. Address: 08048480 */

// void main(void)

// {
//   char local_50 [76];
  
//   gets(local_50);
//   return;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

/*
* Ce code n'est pas 100% fidèle à l'original, mais il est fonctionnel,
* plus lisible et conserve la vulnérabilité à exploiter.
*/

  #include <stdio.h>

  /* Function: run. Address: 08048444 */

  void run(void) {
    printf("Good... Wait what?\n");
    system("/bin/sh");
    return;
  }

  /* Function: main. Address: 08048480 */

  int	main(void) {
    char	buffer[76];

    gets(buffer);
    return 0;
  }
