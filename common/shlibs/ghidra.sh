# This file provides functions to manage Ghidra deassembly and analysis.

# ############# #
# INCLUDE GUARD #
# ############# #

if [ -n "${_GHIDRA_LIB_LOADED:-}" ]; then
    return;
else
    _GHIDRA_LIB_LOADED=1
fi

# ##### #
# UTILS #
# ##### #

_log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*";
}

_assert_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        _log "Error: docker is not installed. Consider installing Docker via 'https://docs.docker.com/engine/install/'" >&2;
        return 1;
    fi
    return 0;
}

_assert_realpath() {
    if ! command -v realpath >/dev/null 2>&1; then
        _log "Error: realpath is not installed." >&2;
        return 1;
    fi
    return 0;
}

# ######### #
# FUNCTIONS #
# ######### #

ghidra_decompile() {
    if [ "$#" -lt 1 ]; then
        echo "Usage: ghidra_decompile <binary_path> [output_path]" >&2;
        return 1;
    fi

    _assert_docker || return 1;
    _assert_realpath || return 1;
    
    ghidra_docker_image="${GHIDRA_DOCKER_IMG:-docker.io/cincan/ghidra-decompiler:ghidra_10.0.1_PUBLIC_20210708}";
    binary_path="$(realpath "$1")";
    output_path="${2:-./decompiled.c}";

    if [ ! -f "$binary_path" ]; then
        _log "Error: invalid binary file path." >&2;
        unset binary_path output_path;
        return 1;
    fi

    if ! docker run --rm -v "${binary_path}:/binary:ro" "$ghidra_docker_image" decompile /binary > "$output_path"; then
        _log "Error: failed to decompile binary." >&2;
        unset ghidra_docker_image binary_path output_path;
        return 1;
    fi

    unset ghidra_docker_image binary_path output_path;
    return 0;
}
