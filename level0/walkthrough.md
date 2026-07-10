# RainFall (level0)

In this project, we try to **exploit binaries**.
By doing so, we wish to read the `/home/user/levelXX/.pass` file, containing our flag serving as the password for the next level.

## Binary decompilation.

It is a **ELF 32-bit x86 LSB** executable as stated by the command `file -b ~/level0` commands.

We also decompiled the binary using [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra). We performed analysis and manual refactoring to isolate the vulnerability and make the relevant C code more readable. The result is saved in the [source.c](./source.c) file and generated through the [decompile.sh](./Ressources/decompile.sh) shell script.

## Binary particularities

This following can be observed by accessing the server via the [ssh.sh](./Ressources/ssh.sh) script.

On login or by executing `checksec --kernel && checksec --file "/home/user/level0/level0"`, we discover:
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

## Discovered vulnerability

This decompiled binary as described in the [source](source.c) file is inherently insecure by design.

It allows to open a shell with escalated privileges based on a given numeric password.

## Vulnerability analysis

The numeric password is hardcoded and thus is easy to retrieve **(423)** through source code analysis. It resolves to **423** and must be provided through `argv[1]`, thus the first argument.
```c
if (atoi(argv[1]) != 423) {
    fputs("No !\n", stderr);
    return 0;
}
```

If valid, it ensure the script's UserID becomes the Effective UserID. This causes a privilege escalation as the user **level1**.
```c
uid_t gid = getegid();
gid_t uid = geteuid();
setresgid(gid, gid, gid);
setresuid(uid, uid, uid);
```

It then calls `execv("/bin/sh", ...)` offering us a **shell** as the user **level1**.
```c
	char *execv_argv[] = {"/bin/sh", NULL};
	execv(execv_argv[0], execv_argv);
```

## Exploit

The exploit is described and performed by the [getflag.sh script](./Ressources/getflag.sh).
