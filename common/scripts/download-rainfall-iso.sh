#!/usr/bin/env sh

URL="https://cdn.intra.42.fr/isos/RainFall.iso"

# ##### #
# UTILS #
# ##### #

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*";
}

assert_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        log "Error: curl is not installed.";
        exit 1;
    fi
}

parse_dirname() {
    path="$1";
    dirname="${path%/*}";

    if [ "$dirname" = "$path" ]; then
        dirname=".";
    fi
    printf '%s\n' "$dirname"
}

parse_filename() {
    path="$1";
    case "$path" in
        */)
            filename="";
            ;;
        .)
            filename="";
            ;;
        *)
            filename="${path##*/}";
            ;;
    esac

    printf '%s\n' "$filename"
}

# #### #
# MAIN #
# #### #

main() {
    if [ "$#" -eq 0 ]; then
        echo "Usage: $0 [filepath.iso]";
        return 0;
    fi

    assert_curl;

    filepath="$1"; shift;
    output_dirname="$(parse_dirname "$filepath")";
    output_filename="$(parse_filename "$filepath")";

    if [ -z "$output_filename" ]; then
        output_filename="RainFall.iso";
    fi

    output_path="$output_dirname/$output_filename";

    if [ -e "$output_path" ]; then
        log "Error: output file ($output_path) already exists." >&2;
        exit 1;
    fi

    case "$output_path" in
        *.iso)
            log "Downloading ISO file to '$output_path'...";
            if curl -L --fail "$URL" -o "$output_path"; then
                log "Download completed successfully.";
            else
                log "Error: failed to download ISO file." >&2;
                exit 1;
            fi
            ;;
        *)
            log "Error: detected filename ($output_filename) does not have a .iso extension." >&2;
            exit 1;
            ;;
    esac
}

main "$@";
