/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: main. Address: 08048424 */

// undefined4 main(undefined4 param_1,int param_2)

// {
//   undefined4 uVar1;
//   undefined1 local_3c [40];
//   int local_14;
  
//   local_14 = atoi(*(char **)(param_2 + 4));
//   if (local_14 < 10) {
//     memcpy(local_3c,*(void **)(param_2 + 8),local_14 * 4);
//     if (local_14 == 0x574f4c46) {
//       execl("/bin/sh","sh",0);
//     }
//     uVar1 = 0;
//   }
//   else {
//     uVar1 = 1;
//   }
//   return uVar1;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <string.h>

/* Function: main. Address: 08048424 */

int main(int argc, char **argv) {
    unsigned int    status_code;
    char            buffer[40];
    int             password;

    password = atoi(argv[1]);
    if (password < 10) {
        memcpy(buffer, argv[2], password * 4);
        if (password == 0x574f4c46) {
            execl("/bin/sh", "sh", NULL);
        }
        status_code = 0;
    } else {
        status_code = 1;
    }

    return status_code;
}
