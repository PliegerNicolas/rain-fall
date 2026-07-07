


void n(void)
{
  system("/bin/cat /home/user/level7/.pass");
  return;
}


void m(void *param_1,int param_2,char *param_3,int param_4,int param_5)

{
  puts("Nope");
  return;
}


void main(int ac,char **av)

{
  char *__dest = malloc(0x40);
  void **f= malloc(4);
  
  *f = m;
  strcpy(__dest, argv[1]);
  
  **f();
  return;
}
