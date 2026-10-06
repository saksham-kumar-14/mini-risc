SRC  := $(wildcard src/*.v)
INC  := -Isrc

build/%.out: tb/%.v $(SRC) | build
	iverilog -g2012 $(INC) -o $@ $< $(SRC)

sim: build/tb_risc.out
	cd build && vvp tb_risc.out && echo done

test:
	@for t in tb/tb_*.v; do n=$$(basename $$t .v); \
	  iverilog -g2012 $(INC) -o build/$$n.out $$t $(SRC) && vvp build/$$n.out || exit 1; done

lint:
	verilator --lint-only -Wall $(INC) src/risc.v

prog/%.hex: prog/%.asm tools/asm.py
	python3 tools/asm.py $< --hex $@ --coe $(@:.hex=.coe)

wave:
	gtkwave build/dump.vcd

build:
	mkdir -p build
