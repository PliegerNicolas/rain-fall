/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: m. Address: 080484f4 */

// void m(void *param_1,int param_2,char *param_3,int param_4,int param_5)

// {
//   time_t tVar1;
  
//   tVar1 = time((time_t *)0x0);
//   printf("%s - %d\n",c,tVar1);
//   return;
// }


// /* Function: main. Address: 08048521 */

// undefined4 main(undefined4 param_1,int param_2)

// {
//   undefined4 *puVar1;
//   void *pvVar2;
//   undefined4 *puVar3;
//   FILE *__stream;
  
//   puVar1 = malloc(8);
//   *puVar1 = 1;
//   pvVar2 = malloc(8);
//   puVar1[1] = pvVar2;
//   puVar3 = malloc(8);
//   *puVar3 = 2;
//   pvVar2 = malloc(8);
//   puVar3[1] = pvVar2;
//   strcpy((char *)puVar1[1],*(char **)(param_2 + 4));
//   strcpy((char *)puVar3[1],*(char **)(param_2 + 8));
//   __stream = fopen("/home/user/level8/.pass","r");
//   fgets(c,0x44,__stream);
//   puts("~~");
//   return 0;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char    c[80];

/* Function: m. Address: 080484f4 */

void    m(void /* ??? */) {
    time_t  current_time;

    current_time = time(NULL);
    printf("%s - %ld\n", c, current_time);
}

/* Function: main. Address: 08048521 */

int main(int argc, char **argv) {
    FILE            *stream;
    struct cntr_s {
        int     id;
        char    *str;
    };
    struct cntr_s   *cntr_a;
    struct cntr_s   *cntr_b;

    cntr_a = malloc(sizeof(*cntr_a));
    cntr_a->id = 1;
    cntr_a->str = malloc(8 * sizeof(*cntr_a->str));

    cntr_b = malloc(sizeof(*cntr_b));
    cntr_b->id = 2;
    cntr_b->str = malloc(8 * sizeof(*cntr_b->str));

    strcpy(cntr_a->str, argv[1]);
    strcpy(cntr_b->str, argv[2]);

    stream = fopen("/home/user/level8/.pass", "r");
    fgets(c, 68, stream);
    puts("~~");

    return 0;
}
