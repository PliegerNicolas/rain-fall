# This file provides functions to manage SSH connections/sockets.

# ############# #
# INCLUDE GUARD #
# ############# #

if [ -n "${_SSHID_LOADED:-}" ]; then
    return;
else
    _SSHID_LOADED=1
fi

# ##### #
# UTILS #
# ##### #

_log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*";
}

# ######### #
# VARIABLES #
# ######### #

host="localhost";
port="4242";
username="level0";
password="level0";

if [ -z "${password}" ]; then
    _log "Error: failed to resolved 'password'." >&2;
    exit 1; # Careful with this.
fi
