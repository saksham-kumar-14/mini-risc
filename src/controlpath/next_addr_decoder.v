`timescale 1ns / 1ps

module next_addr_dec (
    input  wire [31:0] pc_out,
    input  wire [31:0] imm_ext,
    input  wire [25:0] jta,
    input  wire [31:0] rs_data,
    input  wire [31:0] rt_data,    // Second comparison register (routed via rt_sel)
    input  wire [1:0]  pc_src,
    input  wire        is_br,
    input  wire [2:0]  br_t,
    input  wire        ovfl,       // Overflow flag from ALU
    input  wire        sys_force_0,// FSM signal to force PC to 0 (start-up)

    output wire [31:0] next_pc,
    output wire [31:0] inc_pc      // Shared adder output for JAL link
);

    reg br_cond;
    wire signed [31:0] s_rs = rs_data;
    wire signed [31:0] s_rt = rt_data;

    // Branch condition checker
    always @(*) begin
        if (!is_br) begin
            br_cond = 1'b0;
        end else begin
            case (br_t)
                3'b001: br_cond = (rs_data == rt_data); // EQ
                3'b010: br_cond = (rs_data != rt_data); // NE
                3'b011: br_cond = (s_rs < s_rt);        // LT
                3'b100: br_cond = (s_rs <= s_rt);       // LE
                3'b101: br_cond = (s_rs > s_rt);        // GT
                3'b110: br_cond = (s_rs >= s_rt);       // GE
                3'b111: br_cond = ovfl;                 // BV (Overflow)
                default: br_cond = 1'b0;
            endcase
        end
    end

    // One adder computes: PC + (br_true ? offset : 0) + 1
    wire [31:0] offset = br_cond ? imm_ext : 32'b0;
    wire [31:0] adder_out = pc_out + offset + 32'd1;

    assign inc_pc = adder_out; // Stores sequential PC+1 during JAL

    // Final pc_src multiplexer
    reg [31:0] next_pc_reg;
    always @(*) begin
        if (sys_force_0) begin
            next_pc_reg = 32'b0;
        end else begin
            case (pc_src)
                2'b00: next_pc_reg = adder_out;             // PC + 1 or Branch
                2'b01: next_pc_reg = {6'b0, jta};           // J, JAL (Word address)
                2'b10: next_pc_reg = rs_data;               // JR
                2'b11: next_pc_reg = 32'b0;                 // System / Reset
            endcase
        end
    end

    assign next_pc = next_pc_reg;

endmodule
