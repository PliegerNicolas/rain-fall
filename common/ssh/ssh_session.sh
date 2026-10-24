# This file provides functions to manage SSH connections/sockets.

# ############# #
# INCLUDE GUARD #
# ############# #

if [ -n "${_SSH_SESSION_LIB_LOADED:-}" ]; then
    return;
else
    _SSH_SESSION_LIB_LOADED=1
fi

# ##### #
# UTILS #
# ##### #

_log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*";
}

_assert_ssh() {
    if ! command -v ssh >/dev/null 2>&1; then
        _log "Error: ssh is not installed." >&2;
        return 1;
    fi
    return 0;
}

_assert_sshpass() {
    if ! command -v sshpass >/dev/null 2>&1; then
        _log "Error: sshpass is not installed." >&2;
        return 1;
    fi
    return 0;
}

_assert_flock() {
    if ! command -v flock >/dev/null 2>&1; then
        _log "Error: flock is not installed." >&2;
        return 1;
    fi
    return 0;
}

# ######### #
# FUNCTIONS #
# ######### #

ssh_initialize_socket() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: SSHPASS=<password> ssh_initialize_socket <host> <port> <username>" >&2;
        return 1;
    fi

    _assert_ssh || return 1;
    _assert_sshpass || return 1;
    _assert_flock || return 1;

    (
        host="$1";
        port="$2";
        username="$3";

        if [ -z "${SSHPASS:-}" ]; then
            _log "Error: no password provided (define it through the SSHPASS environment variable)." >&2;
            exit 1;
        fi
        export SSHPASS;

        socket_path="/tmp/ssh_mux_${username}_${host}_${port}";
        socket_path_lock="${socket_path}.lock";

        umask 077;
        exec 9<>"$socket_path_lock" || exit 1;
        flock -x 9 || exit 1;

        if [ -S "$socket_path" ] && ssh -S "$socket_path" -O check "$username@$host" 2>/dev/null; then
            exit 0;
        fi

        rm -f "$socket_path"

        sshpass -e \
        ssh -fN \
            -o StrictHostKeyChecking="no" \
            -o UserKnownHostsFile="/dev/null" \
            -o ControlMaster="yes" \
            -o ControlPath="$socket_path" \
            -o ControlPersist="10m" \
            -o ConnectTimeout="5" \
            -p "$port" "$username@$host" 9>&-;

        exit "$?";
    );

    return "$?";
}

ssh_destroy_socket() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: ssh_destroy_socket <host> <port> <username>" >&2;
        return 1;
    fi

    _assert_ssh || return 1;
    _assert_flock || return 1;

    host="$1";
    port="$2";
    username="$3";

    socket_path="/tmp/ssh_mux_${username}_${host}_${port}";
    socket_path_lock="${socket_path}.lock";

    (
        umask 077;
        exec 9<>"$socket_path_lock" || exit 1;
        flock -x 9 || exit 1;               

        if [ -S "$socket_path" ]; then
            ssh -S "$socket_path" -O exit "$username@$host" 2>/dev/null
        fi

        rm -f "$socket_path" "$socket_path_lock"
    )

    unset host port username socket_path socket_path_lock
    return 0;
}

ssh_exec_via_socket() {
    if [ "$#" -lt 4 ]; then
        echo "Usage: ssh_exec_via_socket <host> <port> <username> [command...]" >&2;
        return 1;
    fi

    _assert_ssh || return 1;

    (
        host="$1";
        port="$2";
        username="$3";
        shift 3;
        socket_path="/tmp/ssh_mux_${username}_${host}_${port}";

        if [ ! -S "$socket_path" ] || ! ssh -S "$socket_path" -O check "$username@$host" 2>/dev/null; then
            _log "Error: no active SSH socket for $username@$host:$port. Run ssh_initialize_socket first." >&2;
            exit 1;
        fi

        ssh -S "$socket_path" -p "$port" "$username@$host" "$@";
        exit "$?";
    )

    return "$?";
}
