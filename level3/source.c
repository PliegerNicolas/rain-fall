/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

/* Function: v. Address: 080484a4 */

void v(void)

{
  char local_20c [520];
  
  fgets(local_20c,0x200,stdin);
  printf(local_20c);
  if (m == 0x40) {
    fwrite("Wait what?!\n",1,0xc,stdout);
    system("/bin/sh");
  }
  return;
}


/* Function: main. Address: 0804851a */

void main(void)

{
  v();
  return;
}

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <stdlib.h>

/* In ELF section .bss */

extern int  m;

/* Function: v. Address: 080484a4 */

void    v(void) {
    char    buffer[520];

    fgets(buffer, sizeof(buffer), stdin);
    printf(buffer);
    if (m == 64) {
        puts("Wait what?!\n");
        system("/bin/sh");
    }
}

/* Function: main. Address: 0804851a */

int main(void) {
    v();
    return 0;
}