# This file provides functions to manage SSH connections/sockets.

# ############# #
# INCLUDE GUARD #
# ############# #

if [ -n "${_SSHID_LOADED:-}" ]; then
    return;
else
    _SSHID_LOADED=1
fi

# ######### #
# VARIABLES #
# ######### #

host="localhost";
port="4242";
username="level0";
password="level0";
