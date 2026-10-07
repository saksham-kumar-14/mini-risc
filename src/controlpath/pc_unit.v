`timescale 1ns / 1ps

module pc_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        pc_enable,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc_out
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= 32'b0;
        end else if (pc_enable) begin
            pc_out <= next_pc;
        end
    end

endmodule
