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
		import ghidra.program.model.listing.Function;
		import java.io.File;
		import java.io.PrintWriter;

		public class DecompileToC extends GhidraScript {

		    @Override
		    public void run() throws Exception {
		        if (currentProgram == null) {
		            printerr("No program is currently loaded.");
		            return;
		        }

		        String[] argv = getScriptArgs();
		        String outputFilePath = (argv != null && argv.length > 0) ? argv[0] : "./decompiled.c";

		        File outputFile = new File(outputFilePath);
		        if (outputFile.getParentFile() != null) {
		            outputFile.getParentFile().mkdirs();
		        }

		        DecompInterface decomp = new DecompInterface();
		        try (PrintWriter writer = new PrintWriter(outputFile)) {
		            if (!decomp.openProgram(currentProgram)) {
		                printerr("DecompInterface failed: " + decomp.getLastMessage());
		                return;
		            }

		            for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
		                if (monitor.isCancelled()) {
		                    break;
		                }

		                if (f.isExternal() || f.isThunk() || f.getBody().isEmpty() || f.getParentNamespace().getName().equals("EXTERNAL")) {
		                    continue;
		                }

		                DecompileResults res = decomp.decompileFunction(f, 60, monitor);
		                if (res != null && res.decompileCompleted()) {
		                    String cCode = res.getDecompiledFunction().getC();
		                    if (cCode != null) {
		                        writer.println("// Function: " + f.getName());
		                        writer.println(cCode);
		                        writer.println("\n// " + "=".repeat(40) + "\n");
		                    }
		                } else {
		                    printerr("Failed to decompile: " + f.getName());
		                }
		            }
		        } catch (Exception e) {
		            printerr("Failed to decompile: " + e.getMessage());
		        } finally {
		            decomp.dispose();
		        }
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
