#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)";

### SOURCES ###

. "$CURR_DIR_PATH/.sshid.sh";

# #### #
# MAIN #
# #### #

main() {
    # /!\ $host $port $username and $sshid_password are defined in the source '.sshid.sh' file.

    SSHPASS="$(sshid_password)" sshpass -e \
        ssh -p "$port" \
            -o StrictHostKeyChecking="no" \
            -o UserKnownHostsFile="/dev/null" \
            "$username@$host";
}

main "$@";
