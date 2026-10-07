`timescale 1ns / 1ps

module instruction_bram_rom (
    input  wire        clk,
    input  wire        ic_enable,
    input  wire [31:0] addr,
    output reg  [31:0] inst
);
    reg [31:0] rom [0:1023];
    integer i;

    initial begin
        // Pre-fill memory with 0 (NOPs) so unwritten addresses don't output 'x'
        for (i = 0; i < 1024; i = i + 1) begin
            rom[i] = 32'b0;
        end

        // Read exactly the 10 instructions we provided (indices 0 to 9)
        /* verilator lint_off UNUSEDSIGNAL */
        $readmemh("../prog/test.hex", rom, 0, 9);
        /* verilator lint_on UNUSEDSIGNAL */
    end

    // 1-cycle synchronous read to mimic BRAM behavior
    always @(posedge clk) begin
        if (ic_enable) begin
            inst <= rom[addr[9:0]];
        end
    end

endmodule
