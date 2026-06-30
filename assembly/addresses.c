#include <stdio.h>
#include <stdlib.h>

int main (){
    char holder[10] = "Hello";

    printf("--%p--\n", &holder[0]);
    printf("--%p--\n", &holder[1]);
    printf("--%p--\n", &holder[2]);
    printf("--%p--\n", &holder[3]);
    printf("--%p--\n", &holder[4]);

    printf("--%d--\n", &holder[1] - &holder[0]);
    printf("--%d--\n", &holder[2] - &holder[1]);
    printf("--%d--\n", &holder[3] - &holder[2]);
    return 0;
}