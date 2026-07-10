# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/levelXX/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

We decompile the binary using a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra) through the [decompile.sh](./Ressources/decompile.sh) script.

Following this automated decompilation we perform manual refactoring and analysis to isolate the vulnerability and make the relevant code more readable. The result is saved in the ['source' file](./source.c).

## Binary particularities

This can be observed by executing the [ssh.sh](./Ressources/ssh.sh) script.
This information can also be obtained using: `checksec --kernel && checksec --file "/home/user/level0/level0"`
```sh
GCC stack protector support:            Enabled
Strict user copy checks:                Disabled
Restrict /dev/mem access:               Enabled
Restrict /dev/kmem access:              Enabled
grsecurity / PaX: No GRKERNSEC
Kernel Heap Hardening: No KERNHEAP
System-wide ASLR (kernel.randomize_va_space): Off (Setting: 0)
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX enabled    No PIE          No RPATH   No RUNPATH   /home/user/level0/level0
```

We also discover that the flag is owned by `level1` and has the `setuid` flag set.
```sh
ls -la ~/level0
-rwsr-x---+ 1 level1 users 747441 Mar  6  2016 /home/user/level0/level0
```

Useful documentation:
- Setuid flag (Suid): https://fr.wikipedia.org/wiki/Setuid
- Relocation Read-Only (RELRO): https://ctf101.org/binary-exploitation/relocation-read-only/
- Stack canary: https://ctf101.org/binary-exploitation/stack-canaries/
- No eXecute (NX): https://ctf101.org/binary-exploitation/no-execute/
- Position Independent Code (PIE): https://en.wikipedia.org/wiki/Position-independent_code
- RUNPATH & RPATH: https://en.wikipedia.org/wiki/Rpath
- Address Space Layout Randomization (ASRL): https://ctf101.org/binary-exploitation/address-space-layout-randomization/

## Found vulnerability

This [binary](source.c) is inherently insecure by design.

It asks for a numeric hardcoded "password" *(423)* that needs to be passed as the first argument.
If valid, it ensure the script's UserID becomes the Effective UserID *(level1)*.
It then calls `execv("/bin/sh", ...)` offering us a **shell** with **level1 privileges**.
