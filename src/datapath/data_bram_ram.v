`timescale 1ns / 1ps

module data_bram_ram (
    input  wire        clk,
    input  wire        we,     // Write Enable (from 'st' control signal)
    input  wire [31:0] addr,   // Effective address from ALU
    input  wire [31:0] din,    // Data to store
    output reg  [31:0] dout    // Data loaded from memory
);

    // 1024 x 32-bit Data Memory Array
    reg [31:0] ram [0:1023];

    // Initialize memory to zero for clean simulation
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            ram[i] = 32'b0;
        end
    end

    // Synchronous Read and Write
    always @(posedge clk) begin
        if (we) begin
            // Assuming word-addressed memory mapping to match your PC architecture
            ram[addr[9:0]] <= din;
        end
        // The read data is registered, requiring the 2-cycle multi-cycle LD state in your FSM
        dout <= ram[addr[9:0]];
    end

endmodule
