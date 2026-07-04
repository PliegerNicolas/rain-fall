#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)"

### SOURCES ###

. "$CURR_DIR_PATH/../../common/ghidra/ghidra.sh";

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

    sshpass -p "$password" scp -P "$port" "$username@$host:~/level0" "$CURR_DIR_PATH/level0";
    ghidra_decompile "$CURR_DIR_PATH/level0" "$CURR_DIR_PATH/";
}

main "$@";
