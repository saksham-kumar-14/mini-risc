`timescale 1ns / 1ps

module reg_file (
    input  wire        clk,
    input  wire        we,         // Write Enable
    input  wire [3:0]  rs_addr,    // Read Address 1
    input  wire [3:0]  rt_addr,    // Read Address 2
    input  wire [3:0]  rd_addr,    // Write Address
    input  wire [31:0] write_data,

    output wire [31:0] rs_data,
    output wire [31:0] rt_data
);

    // 16 registers of 32-bit width
    reg [31:0] regs [0:15];

    // Initialize all registers to 0 for simulation cleanliness
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            regs[i] = 32'b0;
        end
    end

    // Asynchronous reads: R0 is hardwired to 0
    assign rs_data = (rs_addr == 4'b0000) ? 32'b0 : regs[rs_addr];
    assign rt_data = (rt_addr == 4'b0000) ? 32'b0 : regs[rt_addr];

    // Synchronous write: ignore writes to R0
    always @(posedge clk) begin
        if (we && (rd_addr != 4'b0000)) begin
            regs[rd_addr] <= write_data;
        end
    end

endmodule
