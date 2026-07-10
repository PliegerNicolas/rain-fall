#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)"

# ##### #
# UTILS #
# ##### #

_log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*";
}

# #### #
# MAIN #
# #### #

main() {
    host="localhost";
    port="4242";
    username="level0";
    password="level0";

    sshpass -p "$password" ssh -p "$port" "$username@$host";
}

main "$@";
