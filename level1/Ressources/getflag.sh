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
    host="${host:-localhost}";
    port="${port:-4242}";
    username="${username:-level1}";
    password="${password}";
    flag="";

    log "Authenticating to SSH server at $host:$port with username '$username' and password '$password'...";

    ssh_initialize_socket "$host" "$port" "$username" "$password" || { log "Error: Failed to initialize SSH socket."; return 1; }
    ssh_exec_via_socket "$host" "$port" "$username" "echo 'Test'";
    # flag=$(echo 'cat /home/user/$(whoami)/.pass' | ssh_exec_via_socket "$host" "$port" "$username" '/home/user/$(whoami)/level0 423');
    ssh_destroy_socket "$host" "$port" "$username" || { log "Error: Failed to destroy SSH socket."; return 1; }

    if [ -z "$flag" ]; then
        log "Error: flag is empty. Something went wrong.";
        return 1;
    fi

    log "Flag '$flag' has been written to '$CURR_DIR_PATH/../flag'";
    echo -n "$flag" > "$CURR_DIR_PATH/../flag";
}

main "$@";
