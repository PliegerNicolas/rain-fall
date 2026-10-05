/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: p. Address: 080484b4 */

// void p(char *param_1,char *param_2)

// {
//   char *pcVar1;
//   char local_100c [4104];
  
//   puts(param_2);
//   read(0,local_100c,0x1000);
//   pcVar1 = strchr(local_100c,10);
//   *pcVar1 = '\0';
//   strncpy(param_1,local_100c,0x14);
//   return;
// }


// /* Function: pp. Address: 0804851e */

// void pp(char *param_1)

// {
//   char cVar1;
//   uint uVar2;
//   char *pcVar3;
//   byte bVar4;
//   char local_34 [20];
//   char local_20 [20];
  
//   bVar4 = 0;
//   p(local_34,&DAT_080486a0);
//   p(local_20,&DAT_080486a0);
//   strcpy(param_1,local_34);
//   uVar2 = 0xffffffff;
//   pcVar3 = param_1;
//   do {
//     if (uVar2 == 0) break;
//     uVar2 = uVar2 - 1;
//     cVar1 = *pcVar3;
//     pcVar3 = pcVar3 + (uint)bVar4 * -2 + 1;
//   } while (cVar1 != '\0');
//   *(undefined2 *)(param_1 + (~uVar2 - 1)) = DAT_080486a4;
//   strcat(param_1,local_20);
//   return;
// }


// /* Function: main. Address: 080485a4 */

// undefined4 main(void)

// {
//   char local_3a [54];
  
//   pp(local_3a);
//   puts(local_3a);
//   return 0;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>

/* Function: p. Address: 080484b4 */

void    p(char *dest, char *user_prompt) {
    char *found_newline;
    char  buffer[4104]; // Initializes the buffer with garbage.

    // Writes the user prompt message.
    puts(user_prompt);

    // Reads up to 4096 raw bytes from the user. No '\n' or '\0' are ensured.
    read(STDIN_FILENO, buffer, 4096);

    // Reads the buffer and assumes there is always a '\n' or '\0' and replaces it with a '\0'.
    // If no '\n' or '\0' os found, it might read freely past the 4096 bytes and out of the buffer.
    found_newline = strchr(buffer, '\n');
    *found_newline = '\0';

    // Copies 20 bytes of buffer to dest.
    // - If buffer is too small, '\0' are appended.
    // - If buffer is >= 20, it is copied as is and doesn't guarantee a null byte.
    strncpy(dest, buffer, 20);
}


/* Function: pp. Address: 0804851e */

void pp(char *dest) {
    char        curr_char;
    unsigned    i;
    char        *dest_cpy;
    char        user_input_1[20];
    char        user_input_2[20];

    // Recupere 2 inputs du user.
    p(user_input_1, " - ");
    p(user_input_2, " - ");

    // Concatene les deux userinputs, separes par un espace.
    // La quantite de bytes ecrits dans dest depend de 'p()' et aucune verification de taille n'est faite.
    strcpy(dest, user_input_1);
    memcpy(dest + strlen(dest), " ", 2);
    strcat(dest, user_input_2);
}

/* Function: main. Address: 080485a4 */

int main(void) {
    char    buffer[54];

    pp(buffer);
    puts(buffer);

    return 0;
}
