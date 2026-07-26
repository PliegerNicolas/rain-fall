/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: n. Address: 08048454 */

// void n(void)

// {
//   system("/bin/cat /home/user/level7/.pass");
//   return;
// }


// /* Function: m. Address: 08048468 */

// void m(void *param_1,int param_2,char *param_3,int param_4,int param_5)

// {
//   puts("Nope");
//   return;
// }


// /* Function: main. Address: 0804847c */

// void main(undefined4 param_1,int param_2)

// {
//   char *__dest;
//   undefined4 *puVar1;
  
//   __dest = malloc(0x40);
//   puVar1 = malloc(4);
//   *puVar1 = m;
//   strcpy(__dest,*(char **)(param_2 + 4));
//   (*(code *)*puVar1)();
//   return;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdlib.h>
#include <stdio.h>

/* Function: n. Address: 08048454 */

void    n(void) {
    system("/bin/cat /home/user/level7/.pass");
}

void    m(arg1, arg2, arg3, arg4, arg5) {
    puts("Nope");
}

int main(int argc, char *argv[]) {
    ...;
}