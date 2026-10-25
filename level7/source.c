
// #include <stdio.h>
// #include <time.h>
// // void m(void *param_1,int param_2,char *param_3,int param_4,int param_5)

// // {
// //   time_t tVar1;
  
// //   tVar1 = time((time_t *)0x0);
// //   printf("%s - %d\n",c,tVar1);
// //   return;
// // }
// #define Buffer 64

// char c[Buffer];

// void m_upgraded(void)
// {
//     char *str = (char *)0x8049960;     // string at 0x8049960
//     time_t t = time(NULL);
    
//     printf("%s - %d\n", str, (int)t);
// }

// int main (){
//   m_upgraded();
//   return 0;

// }

// int main(undefined4 param_1,int param_2)

// {
//   void *puVar1;
//   void *pvVar2;
//   void *puVar3;
//   FILE *__stream;
  
//   puVar1 = malloc(8);
//   *puVar1 = 1;

//   pvVar2 = malloc(8);
//   puVar1[1] = pvVar2;
  
//   puVar3 = malloc(8);
//   *puVar3 = 2;
//   pvVar2 = malloc(8);
//   puVar3[1] = pvVar2;
//   strcpy((char *)puVar1[1],av[1]);
//   strcpy((char *)puVar3[1],av[2]);

//   __stream = fopen("/home/user/level8/.pass","r");
//   fgets(c,0x44,__stream);
//   puts("~~");
//   return 0;
// }

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define BUF_SIZE 0x44  // 68 bytes

char c[BUF_SIZE];  // global buffer, filled from the password file

typedef struct {
    int   id;
    char *data;
} entry_t;

// Ghidra's 5-param signature is bogus — none of param_1..5 are used.
// Only the global `c` and time() are referenced.
void m(void)
{
    time_t now = time(NULL);
    printf("%s - %d\n", c, (int)now);
}

int main(int argc, char **argv)
{
    entry_t *e1 = malloc(sizeof(entry_t));
    e1->id = 1;
    e1->data = malloc(8);   // undersized relative to strcpy target — overflow risk

    entry_t *e2 = malloc(sizeof(entry_t));
    e2->id = 2;
    e2->data = malloc(8);

    strcpy(e1->data, argv[1]);   // param_2+4 == argv[1]
    strcpy(e2->data, argv[2]);   // param_2+8 == argv[2]

    FILE *fp = fopen("/home/user/level8/.pass", "r");
    fgets(c, BUF_SIZE, fp);

    puts("~~");
    return 0;
}