`timescale 1ns / 1ps

module alu_mux (
    input  wire [31:0] rt_data,
    input  wire [31:0] ext_imm,
    input  wire        alu_src,
    output wire [31:0] alu_y
);

    // alu_src = 0 -> Register (rt_data)
    // alu_src = 1 -> Immediate (ext_imm)
    assign alu_y = (alu_src) ? ext_imm : rt_data;

endmodule
