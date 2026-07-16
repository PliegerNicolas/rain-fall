/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: p. Address: 080484d4 */

// void p(void)

// {
//   uint unaff_retaddr;
//   char local_50 [76];
  
//   fflush(stdout);
//   gets(local_50);
//   if ((unaff_retaddr & 0xb0000000) == 0xb0000000) {
//     printf("(%p)\n",unaff_retaddr);
//                     /* WARNING: Subroutine does not return */
//     _exit(1);
//   }
//   puts(local_50);
//   strdup(local_50);
//   return;
// }


// /* Function: main. Address: 0804853f */

// void main(void)

// {
//   p();
//   return;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

/* Function: p. Address: 080484d4 */

void    p(void) {
    char        buffer[76];
    uintptr_t   *ret_addr;

    fflush(stdout);
    gets(buffer);

    ret_addr = (uintptr_t *)(buffer + 80);
    if ((*ret_addr & 0xb0000000) == 0xb0000000) {
        printf("(%p)\n", (void *)*ret_addr);
        exit(1);
    }

    puts(buffer);
    strdup(buffer);
}

/* Function: main. Address: 0804853f */

int main(void) {
    p();
    return 0;
}
