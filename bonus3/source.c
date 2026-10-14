/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: main. Address: 080484f4 */

// undefined4 main(int param_1,int param_2)

// {
//   undefined4 uVar1;
//   int iVar2;
//   char *pcVar3;
//   byte bVar4;
//   char local_98 [65];
//   undefined1 local_57;
//   char local_56 [66];
//   FILE *local_14;
  
//   bVar4 = 0;
//   local_14 = fopen("/home/user/end/.pass","r");
//   pcVar3 = local_98;
//   for (iVar2 = 0x21; iVar2 != 0; iVar2 = iVar2 + -1) {
//     pcVar3[0] = '\0';
//     pcVar3[1] = '\0';
//     pcVar3[2] = '\0';
//     pcVar3[3] = '\0';
//     pcVar3 = pcVar3 + ((uint)bVar4 * -2 + 1) * 4;
//   }
//   if ((local_14 == (FILE *)0x0) || (param_1 != 2)) {
//     uVar1 = 0xffffffff;
//   }
//   else {
//     fread(local_98,1,0x42,local_14);
//     local_57 = 0;
//     iVar2 = atoi(*(char **)(param_2 + 4));
//     local_98[iVar2] = '\0';
//     fread(local_56,1,0x41,local_14);
//     fclose(local_14);
//     iVar2 = strcmp(local_98,*(char **)(param_2 + 4));
//     if (iVar2 == 0) {
//       execl("/bin/sh","sh",0);
//     }
//     else {
//       puts(local_56);
//     }
//     uVar1 = 0;
//   }
//   return uVar1;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* Function: main. Address: 080484f4 */

struct buffers {
    char    pass[66];
    char    tail[66];
};

int main(int argc, char **argv) {
    struct buffers  buf;
    FILE            *pass_file;
    int             idx;

    pass_file = fopen("/home/user/end/.pass", "r");
    memset(&buf, 0, sizeof(buf));

    if (pass_file == NULL || argc != 2)
        return -1;

    // Read the first 66 bytes from the file, filling buf.pass[66].
    fread(buf.pass, 1, sizeof(buf.pass), pass_file);
    // Replaces and enforces '\0' on the last byte of buf.pass[66].
    buf.pass[sizeof(buf.pass) - 1] = 0;

    // Takes any input and converts it to an integer.
    idx = atoi(argv[1]);
    // Replaces at that specific address of the buff.pass[66] buffer the char with a '\0'
    buf.pass[idx] = '\0';

    // Reads the next 65 bytes from the file, filling buf.tail[66]. But the file cursor already reached the end of the file.
    // buf.tail's last byte is never overwritten and has been set to 0 via memset before so no risk of a missing '\0'.
    fread(buf.tail, 1, 65, pass_file);
    // Close the file.
    fclose(pass_file);

    // Open a privileged shell if buf.pass (it's base address) equals the passed idx. 
    if (strcmp(buf.pass, argv[1]) == 0)
        execl("/bin/sh", "sh", 0);
    else
        puts(buf.tail);

    return 0;
}
