/* ************************************************************************* */
/* *                       Decompiled code via GHIDRA                      * */
/* ************************************************************************* */

// /* Function: greetuser. Address: 08048484 */

// void greetuser(void)

// {
//   char local_4c [4];
//   char local_48 [2];
//   char cStack_46;
//   char cStack_45;
//   char local_44 [4];
//   undefined4 local_40;
//   undefined2 local_3c;
//   undefined1 local_3a;
  
//   if (language == 1) {
//     local_4c = (char  [4])DAT_08048717;
//     _local_48 = DAT_0804871b;
//     local_44 = (char  [4])DAT_0804871f;
//     local_40 = DAT_08048723;
//     local_3c = DAT_08048727;
//     local_3a = DAT_08048729;
//   }
//   else if (language == 2) {
//     local_4c = (char  [4])s_Goedemiddag__0804872a._0_4_;
//     _local_48 = s_Goedemiddag__0804872a._4_4_;
//     local_44 = (char  [4])s_Goedemiddag__0804872a._8_4_;
//     local_40 = CONCAT22(local_40._2_2_,s_Goedemiddag__0804872a._12_2_);
//   }
//   else if (language == 0) {
//     local_4c = (char  [4])s_Hello_08048710._0_4_;
//     cStack_46 = s_Hello_08048710[6];
//     local_48 = (char  [2])s_Hello_08048710._4_2_;
//   }
//   strcat(local_4c,&stack0x00000004);
//   puts(local_4c);
//   return;
// }


// /* Function: main. Address: 08048529 */

// undefined4 main(int param_1,int param_2)

// {
//   undefined4 uVar1;
//   int iVar2;
//   char *pcVar3;
//   undefined4 *puVar4;
//   byte bVar5;
//   char local_60 [40];
//   char acStack_38 [36];
//   char *local_14;
  
//   bVar5 = 0;
//   if (param_1 == 3) {
//     pcVar3 = local_60;
//     for (iVar2 = 0x13; iVar2 != 0; iVar2 = iVar2 + -1) {
//       pcVar3[0] = '\0';
//       pcVar3[1] = '\0';
//       pcVar3[2] = '\0';
//       pcVar3[3] = '\0';
//       pcVar3 = pcVar3 + 4;
//     }
//     strncpy(local_60,*(char **)(param_2 + 4),0x28);
//     strncpy(acStack_38,*(char **)(param_2 + 8),0x20);
//     local_14 = getenv("LANG");
//     if (local_14 != (char *)0x0) {
//       iVar2 = memcmp(local_14,&DAT_0804873d,2);
//       if (iVar2 == 0) {
//         language = 1;
//       }
//       else {
//         iVar2 = memcmp(local_14,&DAT_08048740,2);
//         if (iVar2 == 0) {
//           language = 2;
//         }
//       }
//     }
//     pcVar3 = local_60;
//     puVar4 = (undefined4 *)&stack0xffffff50;
//     for (iVar2 = 0x13; iVar2 != 0; iVar2 = iVar2 + -1) {
//       *puVar4 = *(undefined4 *)pcVar3;
//       pcVar3 = pcVar3 + ((uint)bVar5 * -2 + 1) * 4;
//       puVar4 = puVar4 + (uint)bVar5 * -2 + 1;
//     }
//     uVar1 = greetuser();
//   }
//   else {
//     uVar1 = 1;
//   }
//   return uVar1;
// }

/* ************************************************************************* */
/* *                      Manually reconstructed code                      * */
/* ************************************************************************* */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int language = 0;

struct buffers {
    char    name[40];
    char    other[36];
};

void    greetuser(struct buffers buf) {
    char    greeting[72];

    // By chosing a longer language, the strconcat allows us to extend the overflow.
    if (language == 1)
        memcpy(greeting, "Hyvää päivää ", 19);
    else if (language == 2)
        memcpy(greeting, "Goedemiddag! ", 14);
    else
        memcpy(greeting, "Hello ", 7);

    // 19 + 40 = 59 should fit inside the buffer.
    // If buf.name misses a '\0' then it can be considered as a 40 + 36 = 76 bytes buffer and trigger an overflow of greetuser's return address.
    strcat(greeting, buf.name);
    puts(greeting);
}

int main(int argc, char **argv) {
    struct buffers buf;
    char        *lang;

    if (argc != 3)
        return 1;

    memset(&buf, 0, sizeof(buf));

    // Does not enforce a '\0' while filling the buffer.
    // This can trigger reading over buf.name inside buf.other, these being contiguous.
    strncpy(buf.name,  argv[1], sizeof(buf.name));
    strncpy(buf.other, argv[2], 32);

    lang = getenv("LANG");
    if (lang != NULL) {
        if (memcmp(lang, "fi", 2) == 0)
            language = 1;
        else if (memcmp(lang, "nl", 2) == 0)
            language = 2;
    }

    greetuser(buf);

    return 0;
}
