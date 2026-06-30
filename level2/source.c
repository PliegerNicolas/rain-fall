#include <cstdio>

void p(void){

  uint unaff_retaddr;
  char local_50 [76];
  
  fflush(stdout);
  gets(local_50);
  if ((unaff_retaddr & 0xb0000000) == 0xb0000000) {
    // 1 only if two bits are 1
    printf("(%p)\n",unaff_retaddr);
                    /* WARNING: Subroutine does not return */
    _exit(1);
  }
  puts(local_50);
  strdup(local_50);
  return;
}

void main(void)

{
  p();
  return;
}


unaff_retaddr = 0xbfff0000 & 0xb0000000
10111111111111110000000000000000 & 10110000000000000000000000000000

10110000000000000000000000000000