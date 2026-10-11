`timescale 1ns / 1ps

module instruction_bram_rom (
    input  wire        clka,
    input  wire        ena,
    input  wire [31:0] addra,
    output reg  [31:0] douta
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
    always @(posedge clka) begin
        if (ena) begin
            douta <= rom[addra[9:0]];
        end
    end

endmodule
