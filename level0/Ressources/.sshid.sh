# This file provides variables and functions for authentication purpose.
# It is meant to be used with "$CURR_DIR_PATH/../../common/ssh/ssh_session.sh".

# ############# #
# INCLUDE GUARD #
# ############# #

if [ -n "${_SSHID_LOADED:-}" ]; then
    return;
else
    _SSHID_LOADED=1
fi

# ########## #
# IDENTITY   #
# ########## #

host="localhost";
port="4242";
username="level0";

password_file=""
sshid_password() {
    printf '%s' 'level0';
}

# password_file="$(cd "$(dirname "$0")" && pwd)/../../level00/flag";
# sshid_password() {
#     if [ ! -f "$password_file" ]; then
#         echo "Error: password/flag file not found: '$password_file'." >&2;
#         return 1;
#     fi

#     cat "$password_file";
# }
