# RainFall (bonus3)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/bonus3/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the `file -b ~/bonus3` command.

We use `objdump -d ~/bonus3` to disassemble the binary. We stored its truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/bonus3`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX enabled    No PIE          No RPATH   No RUNPATH   /home/user/bonus3/bonus3
```

The binary is owned by `end` and has the `setuid` flag set.
```sh
$ ls -la ~/bonus3
-rwsr-s---+ 1 end users 5595 Mar  6  2016 /home/user/bonus3/bonus3
```

Useful documentation:
- Setuid flag (Suid): https://fr.wikipedia.org/wiki/Setuid
- Relocation Read-Only (RELRO): https://ctf101.org/binary-exploitation/relocation-read-only/
- Stack canary: https://ctf101.org/binary-exploitation/stack-canaries/
- No eXecute (NX): https://ctf101.org/binary-exploitation/no-execute/
- Position Independent Code (PIE): https://en.wikipedia.org/wiki/Position-independent_code
- RUNPATH & RPATH: https://en.wikipedia.org/wiki/Rpath
- Address Space Layout Randomization (ASRL): https://ctf101.org/binary-exploitation/address-space-layout-randomization/

## Discovered vulnerability & analysis

The process has its NX feature enabled, so stack shellcode execution won't be possible.  
We will have to abuse the existing code behaviour instead of redirecting control flow.

We discover two main oddities, both with the user input as their central component:  
- We can inject a `'\0'` anywhere we desire on the stack. We can shorten strings, alter multi-byte values, trigger crashes...
- The privileged shell opportunity is hidden behind a user-controlled condition that also depends on the content of `buf.pass`. With the right strategy we can potentially make the condition true.

The decompiled binary (cf. [source](source.c)) seems to be subject to an Improper Input Validation ([CWE-20](https://cwe.mitre.org/data/definitions/20.html)).

### Stack

Let's first verify the stack to understand better what' happening behind. We could maybe find specific opportunities from there.

`main()`'s stack frame should resemble something like this:
```ruby
      HIGHER MEMORY ADDRESSES     
| |      argv     | (4 bytes)    | <-- ['./bonus3', arg1];
| +---------------+              |
| |      argc     | (4 bytes)    |
+--------------------------------+
|      main's return address     | (4 bytes)
+--------------------------------+ <--- main's Stack Frame start (@ 0xbffffe5c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- main's local variables start (EBP: @ 0xbffffe58)
| |   saved reg.  | (8 bytes)    |
| +---------------+              |
| |   pass_file   | (4 bytes)    |
| +-----+---------+              |
| |     |  tail   | (66 bytes)   | (168 bytes)
| | buf +---------+  (132 bytes) |
| |     |  pass   | (66 bytes)   |
| +-----+---------+ (0xbffffdc8) |
| |   call args   | (24 bytes)   |
+--------------------------------+ <--- main's Stack Pointer (ESP: @ 0xbffffdb0)
      LOWER MEMORY ADDRESSES      
```

The addresses noted here are the ones observed under `env -i ./bonus3 "1111111111"`, assuming an decimal representation of an hex address is in that range of length.
Process arguments being written before `main()`'s stackframe, they push it downwards.


### Intent

Find an input that satisfies the condition `strcmp(buf.pass, argv[1] == 0`.

## Exploit

Our first instinct would be to pass `0`:
- argv[1] as a string would be: `"0"`
- atoi(argv[1]) as an integer would resolve to: `0`.
- `buff.pass` as a string would be: `""`.
This does not work. But it drove us to another idea.

We know by experience that passing `""` would drive the following result:
- argv[1] as a string would be: `""`
- atoi(argv[1]) as an integer would resolve to: `0`.
- `buff.pass` as a string would be: `""`.
This matches and the door opens up. We won.

```sh
./bonus3 "";
```
