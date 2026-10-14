#!/usr/bin/env sh

### GLOBALS ###

CURR_DIR_PATH="$(cd "$(dirname "$0")" && pwd)"

### SOURCES ###

. "$CURR_DIR_PATH/.sshid.sh";

# #### #
# MAIN #
# #### #

main() {
    host="${host:-localhost}";
    port="${port:-4242}";
    username="${username:-level1}";
    password="${password}";

    sshpass -p "$password" ssh -p "$port" "$username@$host";
}

main "$@";
