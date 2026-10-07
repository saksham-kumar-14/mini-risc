# Directories
BUILD_DIR = build
SRC_DIR = src
TB_DIR = testbench

# Collect all Verilog source files (excluding testbench for linting)
SRCS = $(wildcard $(SRC_DIR)/datapath/*.v) \
       $(wildcard $(SRC_DIR)/controlpath/*.v) \
       $(wildcard $(SRC_DIR)/*.v)

TB = $(TB_DIR)/tb_risc.v
SIM_BIN = $(BUILD_DIR)/minirisc.vvp
WAVE_FILE = $(BUILD_DIR)/minirisc_wave.vcd

.PHONY: all sim test lint format wave clean

all: sim

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile the design and testbench with Icarus Verilog
$(SIM_BIN): $(SRCS) $(TB) | $(BUILD_DIR)
	iverilog -o $@ $(SRCS) $(TB)

# Run the simulation (Satisfies 'scripts.sim.exec' and 'scripts.test.exec')
sim test: $(SIM_BIN)
	cd $(BUILD_DIR) && vvp $(notdir $(SIM_BIN))

# Lint the source files using Verilator (Satisfies 'scripts.lint.exec' and 'git-hooks')
# The testbench is intentionally excluded here as testbenches often contain non-synthesizable constructs that Verilator rejects.
lint:
	verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL $(SRCS)

# Format the code using Verible (Leveraging pkgs.verible from your devenv.nix)
format:
	verible-verilog-format --inplace $(SRCS) $(TB)

# View the generated VCD waveform in GTKWave (Leveraging pkgs.gtkwave)
wave: sim
	gtkwave $(WAVE_FILE) &

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)/*
