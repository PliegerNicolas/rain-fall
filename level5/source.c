/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: o. Address: 080484a4 */

// void o(void)

// {
//   system("/bin/sh");
//                     /* WARNING: Subroutine does not return */
//   _exit(1);
// }


// /* Function: n. Address: 080484c2 */

// void n(void)

// {
//   char local_20c [520];
  
//   fgets(local_20c,0x200,stdin);
//   printf(local_20c);
//                     /* WARNING: Subroutine does not return */
//   exit(1);
// }


// /* Function: main. Address: 08048504 */

// void main(void)

// {
//   n();
//   return;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>

/* Function: o. Address: 080484a4 */

void    o(void) {
    system("/bin/sh");
    exit(1);
}

/* Function: n. Address: 080484c2 */

void    n(void) {
    char    buffer[520];

    fgets(buffer, sizeof(buffer), stdin);
    printf(buffer);
    exit(1);
}

/* Function: main. Address: 08048504 */

int main(void) {
    n();
    return 0;
}