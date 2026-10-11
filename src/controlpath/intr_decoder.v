`timescale 1ns / 1ps

module instruction_decoder (
    input  wire [31:0] inst,

    // Control signals mapping directly to the Appendix A table
    output reg  [1:0]  reg_dst,
    output reg         hi_lo,
    output reg         reg_wr,
    output reg         alu_src,
    output reg  [5:0]  alu_func,
    output reg         ld,         // mem_read
    output reg         st,         // mem_write
    output reg  [1:0]  reg_in,
    output reg  [1:0]  pc_src,
    output reg         is_br,
    output reg  [2:0]  br_t,
    output reg         frz,
    output reg  [2:0]  rt_sel,
    output reg         halt
);

    wire [5:0] opcode  = inst[31:26];
    wire [5:0] inst_fn = inst[5:0];

    always @(*) begin
        // 1. Set safe defaults for all control signals
        reg_dst  = 2'b00;
        hi_lo    = 1'b0;
        reg_wr   = 1'b0;
        alu_src  = 1'b0;
        alu_func = 6'b000000;
        ld       = 1'b0;
        st       = 1'b0;
        reg_in   = 2'b00;
        pc_src   = 2'b00;
        is_br    = 1'b0;
        br_t     = 3'b000;
        frz      = 1'b0;
        rt_sel   = 3'b000;
        halt     = 1'b0;

        // 2. Decode opcodes based on the provided ISA table
        case (opcode)
            // NOP
            6'b000000: begin
                // All defaults are 0, matches NOP perfectly
            end

            // R-type
            6'b100000: begin
                reg_dst  = 2'b01;
                reg_wr   = 1'b1;
                alu_src  = 1'b0;
                alu_func = inst_fn;
                reg_in   = 2'b01;
                if (inst_fn == 6'b010011) begin // MULU
                    reg_dst = 2'b10;
                    hi_lo   = 1'b1;
                end
            end

            // I-type ALU Immediate Instructions
            6'b110000: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b010000; reg_in = 2'b01; end // ADDI
            6'b110001: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b010001; reg_in = 2'b01; end // SUBI
            6'b110010: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b011000; reg_in = 2'b01; end // ANDI
            6'b110011: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b011001; reg_in = 2'b01; end // ORI
            6'b110100: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b011011; reg_in = 2'b01; end // NORI
            6'b110101: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b011100; reg_in = 2'b01; end // XORI
            6'b110110: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b100000; reg_in = 2'b01; end // SLLI
            6'b110111: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b100001; reg_in = 2'b01; end // SRLI
            6'b111000: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b100010; reg_in = 2'b01; end // SRAI
            6'b111001: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b001000; reg_in = 2'b01; end // SLTI
            6'b111010: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b001001; reg_in = 2'b01; end // SGTI
            6'b111011: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b001010; reg_in = 2'b01; end // SLEI
            6'b111100: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b001011; reg_in = 2'b01; end // SGEI
            6'b111101: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b001100; reg_in = 2'b01; end // SEQI
            6'b111110: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b001101; reg_in = 2'b01; end // SNEI

            // Constants
            6'b100010: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b010000; reg_in = 2'b01; frz = 1'b1; end // LI
            6'b100011: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b000000; reg_in = 2'b01; end // LUI

            // Moves
            6'b100100: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b0; alu_func = 6'b010000; reg_in = 2'b01; rt_sel = 3'b010; end // MOVE
            6'b100001: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b0; alu_func = 6'b010000; reg_in = 2'b01; frz = 1'b1; rt_sel = 3'b011; end // MFHI
            6'b100111: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b0; alu_func = 6'b010000; reg_in = 2'b01; frz = 1'b1; rt_sel = 3'b100; end // MFLO

            // Memory accesses (FIXED alu_func to 010000 to match ADDI's ADD operation)
            6'b100101: begin reg_dst = 2'b01; reg_wr = 1'b1; alu_src = 1'b1; alu_func = 6'b010000; ld = 1'b1; reg_in = 2'b00; end // LD
            6'b100110: begin reg_dst = 2'b00; reg_wr = 1'b0; alu_src = 1'b1; alu_func = 6'b010000; st = 1'b1; rt_sel = 3'b001; end // ST

            // Jumps
            6'b101000: begin pc_src = 2'b01; end // J
            6'b101001: begin reg_dst = 2'b11; reg_wr = 1'b1; reg_in = 2'b10; pc_src = 2'b01; end // JAL
            6'b101011: begin pc_src = 2'b10; end // JR

            // Conditional Branches
            6'b010000: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b001; rt_sel = 3'b001; end // BEQ
            6'b010001: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b001; rt_sel = 3'b010; end // BZ
            6'b010010: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b010; rt_sel = 3'b001; end // BNE
            6'b010011: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b011; rt_sel = 3'b001; end // BLT
            6'b010100: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b100; rt_sel = 3'b001; end // BLE
            6'b010101: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b101; rt_sel = 3'b001; end // BGT
            6'b010110: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b110; rt_sel = 3'b001; end // BGE
            6'b010111: begin alu_func = 6'b010001; is_br = 1'b1; br_t = 3'b111; rt_sel = 3'b001; end // BV

            // System
            6'b111111: begin halt = 1'b1; end // HALT

            default: begin
                // Invalid opcode triggers halt
                halt = 1'b1;
            end
        endcase
    end
endmodule
