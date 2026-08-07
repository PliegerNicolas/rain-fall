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
username="level8";
password="$(cat ../../level7/flag 2>/dev/null)"; # TODO: not flexible enough.

if [ -z "${password}" ]; then
    _log "Error: failed to resolve 'password'." >&2;
    exit 1; # Careful with this.
fi
