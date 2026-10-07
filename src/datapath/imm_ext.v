`timescale 1ns / 1ps

module imm_ext (
    input  wire [15:0] imm_in,
    input  wire        alu_src,    // 1 if instruction uses immediate
    input  wire [2:0]  alu_unit,   // alu_func[5:3] to detect logic ops
    output wire [31:0] imm_out
);

    // Zero extend if it's an immediate instruction AND a logic operation (011)
    wire is_logic_imm = alu_src && (alu_unit == 3'b011);

    assign imm_out = is_logic_imm ?
                     {16'b0, imm_in} :                   // Zero extension
                     {{16{imm_in[15]}}, imm_in};         // Sign extension

endmodule
