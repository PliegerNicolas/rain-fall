/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: p. Address: 08048444 */

// void p(char *param_1)

// {
//   printf(param_1);
//   return;
// }

// /* Function: n. Address: 08048457 */

// void n(void)

// {
//   char local_20c [520];
  
//   fgets(local_20c,0x200,stdin);
//   p(local_20c);
//   if (m == 0x1025544) {
//     system("/bin/cat /home/user/level5/.pass");
//   }
//   return;
// }

// /* Function: main. Address: 080484a7 */

// void main(void)

// {
//   n();
//   return;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <stdlib.h>

int m;

void    p(char *buffer) {
    printf(buffer);
}

void    n(void) {
    char    buffer[520];

    fgets(buffer, 512, stdin);
    p(buffer);
    if (m == 16930116)
        system("/bin/cat /home/user/level5/.pass");
}

int main(void) {
    n();
    return 0;
}
