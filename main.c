#include<stdio.h>

int main (){
    buffer[40] = "aaaa%d";
    int a;

    printf(buffer);

    return 0;
}

//              ret addr 4 byte
// |||||||||||| ebp 4 byte

// buffer 520 addr + other stuff


// |||||||||||| esp

// %4$n

// printf("tt", 1, 2, 2, "4byte adress m")