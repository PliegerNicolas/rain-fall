/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: main. Address: 08048564 */

// undefined4 main(void)

// {
//   char cVar1;
//   char *pcVar2;
//   char *pcVar3;
//   char *pcVar4;
//   int iVar5;
//   uint uVar6;
//   byte *pbVar7;
//   byte *pbVar8;
//   bool bVar9;
//   undefined1 uVar10;
//   undefined1 uVar11;
//   undefined1 uVar12;
//   bool bVar13;
//   undefined1 uVar14;
//   byte bVar15;
//   byte local_90 [5];
//   char local_8b [2];
//   char acStack_89 [125];
  
//   bVar15 = 0;
//   do {
//     printf("%p, %p \n",auth,service);
//     pcVar4 = fgets((char *)local_90,0x80,stdin);
//     bVar9 = false;
//     if (pcVar4 == (char *)0x0) {
//       return 0;
//     }
//     iVar5 = 5;
//     bVar13 = false;
//     pbVar7 = local_90;
//     pbVar8 = &DAT_08048819;
//     do {
//       if (iVar5 == 0) break;
//       iVar5 = iVar5 + -1;
//       bVar9 = *pbVar7 < *pbVar8;
//       bVar13 = *pbVar7 == *pbVar8;
//       pbVar7 = pbVar7 + (uint)bVar15 * -2 + 1;
//       pbVar8 = pbVar8 + (uint)bVar15 * -2 + 1;
//     } while (bVar13);
//     uVar10 = 0;
//     uVar14 = 0;
//     if ((!bVar9 && !bVar13) == bVar9) {
//       auth = malloc(4);
//       pcVar4 = auth + 1;
//       pcVar2 = auth + 2;
//       pcVar3 = auth + 3;
//       auth[0] = '\0';
//       *pcVar4 = '\0';
//       *pcVar2 = '\0';
//       *pcVar3 = '\0';
//       uVar6 = 0xffffffff;
//       pcVar4 = local_8b;
//       do {
//         if (uVar6 == 0) break;
//         uVar6 = uVar6 - 1;
//         cVar1 = *pcVar4;
//         pcVar4 = pcVar4 + (uint)bVar15 * -2 + 1;
//       } while (cVar1 != '\0');
//       uVar6 = ~uVar6 - 1;
//       uVar10 = uVar6 < 0x1e;
//       uVar14 = uVar6 == 0x1e;
//       if (uVar6 < 0x1f) {
//         strcpy(auth,local_8b);
//       }
//     }
//     iVar5 = 5;
//     pbVar7 = local_90;
//     pbVar8 = (byte *)"reset";
//     do {
//       if (iVar5 == 0) break;
//       iVar5 = iVar5 + -1;
//       uVar10 = *pbVar7 < *pbVar8;
//       uVar14 = *pbVar7 == *pbVar8;
//       pbVar7 = pbVar7 + (uint)bVar15 * -2 + 1;
//       pbVar8 = pbVar8 + (uint)bVar15 * -2 + 1;
//     } while ((bool)uVar14);
//     uVar11 = 0;
//     uVar14 = (!(bool)uVar10 && !(bool)uVar14) == (bool)uVar10;
//     if ((bool)uVar14) {
//       free(auth);
//     }
//     iVar5 = 6;
//     pbVar7 = local_90;
//     pbVar8 = (byte *)"service";
//     do {
//       if (iVar5 == 0) break;
//       iVar5 = iVar5 + -1;
//       uVar11 = *pbVar7 < *pbVar8;
//       uVar14 = *pbVar7 == *pbVar8;
//       pbVar7 = pbVar7 + (uint)bVar15 * -2 + 1;
//       pbVar8 = pbVar8 + (uint)bVar15 * -2 + 1;
//     } while ((bool)uVar14);
//     uVar12 = 0;
//     uVar10 = 0;
//     if ((!(bool)uVar11 && !(bool)uVar14) == (bool)uVar11) {
//       uVar12 = (byte *)0xfffffff8 < local_90;
//       uVar10 = acStack_89 == (char *)0x0;
//       service = strdup(acStack_89);
//     }
//     iVar5 = 5;
//     pbVar7 = local_90;
//     pbVar8 = (byte *)"login";
//     do {
//       if (iVar5 == 0) break;
//       iVar5 = iVar5 + -1;
//       uVar12 = *pbVar7 < *pbVar8;
//       uVar10 = *pbVar7 == *pbVar8;
//       pbVar7 = pbVar7 + (uint)bVar15 * -2 + 1;
//       pbVar8 = pbVar8 + (uint)bVar15 * -2 + 1;
//     } while ((bool)uVar10);
//     if ((!(bool)uVar12 && !(bool)uVar10) == (bool)uVar12) {
//       if (*(int *)(auth + 0x20) == 0) {
//         fwrite("Password:\n",1,10,stdout);
//       }
//       else {
//         system("/bin/sh");
//       }
//     }
//   } while( true );
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct auth_s {
    char    login[32];
    bool    privileged;
};

char    *auth = NULL;
char    *service = NULL;

/* Function: main. Address: 08048564 */

int main(void) {
    char    buffer[128];
    char    *arg;

    while (true) {
        printf("%p, %p \n", auth, service);

        if (fgets(buffer, 128, stdin) == NULL)
            return 0;

        if (strncmp(buffer, "auth ", 5) == 0) {
            auth = (char *)calloc(4, sizeof(*auth));
            arg = buffer + 5;
            if (strlen(arg) < 31)
                strcpy(auth, arg);
        } else if (strncmp(buffer, "reset", 5) == 0 && auth != NULL) {
            free(auth);
        } else if (strncmp(buffer, "servic", 6) == 0) {
            arg = buffer + 7;
            service = strdup(arg);
        } else if (strncmp(buffer, "login", 5) == 0) {
            bool    privileged = ((struct auth_s *)auth)->privileged;
            if (privileged != 0) {
                system("/bin/sh");
            } else {
                fwrite("Password:\n", 1, 10, stdout);
            }
        }
    }

    return 0;
}
