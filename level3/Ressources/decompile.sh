#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)"

### SOURCES ###

. "$CURR_DIR_PATH/../../common/ghidra/ghidra.sh";
. "$CURR_DIR_PATH/.sshid.sh";

# #### #
# MAIN #
# #### #

main() {
    host="${host:-localhost}";
    port="${port:-4242}";
    username="${username:-level3}";
    password="${password}";

    remote_binary_path="~/level3";
    local_binary_path="$CURR_DIR_PATH/level3";

    sshpass -p "$password" scp -P "$port" "$username@$host:$remote_binary_path" "$local_binary_path";
    ghidra_decompile "$local_binary_path" "$CURR_DIR_PATH/";
    rm -f "$local_binary_path";
}

main "$@";
