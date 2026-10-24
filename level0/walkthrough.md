# RainFall (level0)

In this project, we try to **exploit binaries** with the intent of reading the `/home/users/level<n+1>/.pass` file, containing our flag serving as the password for the next level.

# Binary

Binary properties:
- Full path: `/home/user/level0/level0`
- Type: **ELF 32-bit LSB executable** (`file -b ~/level0`)

To analyze its content we generated two files:
- [source.c](./source.c): generated with our [ghidra.sh](../common/ghidra/ghidra.sh), wrapping a [Ghidra](https://github.com/nationalsecurityagency/ghidra)-based [docker container](https://hub.docker.com/r/blacktop/ghidra).
- [source.asm](./source.asm): trimmed after being generated through `objdump -D ~/level0`.

# Security

Let's connect to the server through [ssh](./Ressources/ssh.sh) and inspect the protections in place.

## File Attributes

```sh
$ ls -la ~/level0
-rwsr-x---+ 1 level1 users 747441 Mar  6  2016 /home/user/level0/level0
```

These describe the binary's privileges.
|    Attribute    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|    Suid bit     |    ✅     | Runs with level1's effective id: opening a shell inherits it.


## Compile-Time

```sh
$ checksec --file ~/level0
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
No RELRO        No canary found   NX enabled    No PIE          No RPATH   No RUNPATH   /home/user/level0/level0
```

These are the protections baked directly into the binary.
|   Protection    |   State   |                           Meaning for us                           |
|       ---       |    ---    |                                ---                                 |
|      RELRO      |    ❌     | GOT is writable.
|  Stack Canary   |    ❌     | Stack buffer overflows are possible.
|       NX        |    ✅     | Stack/Heap are non-executable. Shellcode injection is not possible.
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
