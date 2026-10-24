#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)";

### SOURCES ###

. "$CURR_DIR_PATH/../../common/ghidra/ghidra.sh";
. "$CURR_DIR_PATH/.sshid.sh";

# #### #
# MAIN #
# #### #

main() {
    # /!\ $host $port $username and $sshid_password are defined in the source '.sshid.sh' file.

    remote_binary_path="~/$username";
    local_binary_path="$CURR_DIR_PATH/$username";

    SSHPASS="$(sshid_password)" sshpass -e \
        scp -P "$port" \
            -o StrictHostKeyChecking="no" \
            -o UserKnownHostsFile="/dev/null" \
            "$username@$host:$remote_binary_path" "$local_binary_path" || return 1;

    ghidra_decompile "$local_binary_path" "$CURR_DIR_PATH/";
    rm -f "$local_binary_path";
}

main "$@";
