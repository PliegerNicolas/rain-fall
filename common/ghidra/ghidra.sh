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

_get_decompile_to_c_script() {
	cat <<-'EOF'
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.listing.Function;

import java.io.File;
import java.io.PrintWriter;

public class DecompileToC extends GhidraScript {

    private String getOutputPath() {
        String[] args = getScriptArgs();
        return args.length > 0 ? args[0] : "./decompiled.c";
    }

    private boolean ignoreFunction(Function f) {
        if (f.isThunk() || f.isExternal() || f.isLibrary())
            return true;
        if (f.getBody().getNumAddresses() == 0)
            return true;
        String funcName = f.getName();
        if (funcName.startsWith("__") || funcName.equals("_init") || funcName.equals("_fini") || funcName.equals("_start"))
            return true;
        return false;
    }

    @Override
    public void run() throws Exception {
        if (currentProgram == null) {
            printerr("No program loaded.");
            return;
        }

        File outputFile = new File(getOutputPath());
        FunctionManager funcMgr = currentProgram.getFunctionManager();
        DecompInterface decomp = new DecompInterface();

        if (!decomp.openProgram(currentProgram)) {
            printerr("Decompiler init failed: " + decomp.getLastMessage());
            decomp.dispose();
            return;
        }

        try (PrintWriter writer = new PrintWriter(outputFile)) {
            for (Function f : funcMgr.getFunctions(true)) {
                if (ignoreFunction(f))
                    continue;

                DecompileResults results = decomp.decompileFunction(f, 60, monitor);

                if (!results.decompileCompleted()) {
                    printerr("Failed to decompile function: " + f.getName() + ". Error: " + results.getErrorMessage());
                    continue;
                }

                writer.println("/* Function: " + f.getName() + ". Address: " + f.getEntryPoint() + " */");
                writer.println(results.getDecompiledFunction().getC());
            }
        } catch (Exception e) {
            printerr("Failed to write/decompile: " + e.getMessage());
        } finally {
            decomp.dispose();
        }

        println("Decompilation completed. Output written to: " + outputFile.getAbsolutePath());
    }
}
	EOF
}

# ######### #
# FUNCTIONS #
# ######### #

ghidra_decompile() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: ghidra_decompile <binary_path> <output_directory>" >&2;
        return 1;
    fi

    _assert_docker || return 1;
    _assert_realpath || return 1;
    
    binary_input_path_local="$(realpath "$1")";
    c_output_dir_local="${2:-./}";

    if [ ! -f "$binary_input_path_local" ]; then
        _log "Error: invalid binary file path." >&2;
        unset binary_input_path_local c_output_dir_local;
        return 1;
    fi

    if [ ! -d "$c_output_dir_local" ]; then
        _log "Error: invalid output directory." >&2;
        unset binary_input_path_local c_output_dir_local;
        return 1;
    fi

    (
        post_script_path_local="$(mktemp --suffix .java /tmp/DecompileToC.XXXXXXXXXX)";
        trap 'rm -f -- "$post_script_path_local"' EXIT INT TERM HUP;
        post_script_path_docker="/ghidra_scripts/DecompileToC.java";
        _get_decompile_to_c_script > "$post_script_path_local";

        docker run --init --rm \
            --cpus="2" \
            --memory="4G" \
            --env MAXMEM=4G \
            --volume "${binary_input_path_local}:/in/binary:ro" \
            --volume "${c_output_dir_local}:/out" \
            --volume "${post_script_path_local}:${post_script_path_docker}:ro" \
            blacktop/ghidra:latest \
            /ghidra/support/analyzeHeadless /tmp Project \
            -import /in/binary \
            -scriptPath /ghidra_scripts \
            -postScript DecompileToC.java "/out/decompiled.c" \
            -deleteProject;
    )
}
