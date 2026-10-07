`timescale 1ns / 1ps

module alu (
    input  wire [31:0] x,
    input  wire [31:0] y,
    input  wire [5:0]  alu_func,
    output reg  [31:0] alu_out,
    output wire        ovfl
);

    wire [2:0] unit = alu_func[5:3];
    wire [2:0] op   = alu_func[2:0];

    // Signed wire definitions for accurate arithmetic/arithmetic shifts
    wire signed [31:0] signed_x = x;
    wire signed [31:0] signed_y = y;

    // Overflow flag (only relevant for ADD/SUB, simplified for this scope)
    assign ovfl = (unit == 3'b010 && op == 3'b000) ?
                  ((x[31] == y[31]) && (alu_out[31] != x[31])) :
                  (unit == 3'b010 && op == 3'b001) ?
                  ((x[31] != y[31]) && (alu_out[31] != x[31])) : 1'b0;

    always @(*) begin
        alu_out = 32'b0; // Default to prevent latches

        case (unit)
            3'b000: begin // Load-upper (LUI)
                if (op == 3'b000) alu_out = {y[15:0], 16'b0};
            end

            3'b001: begin // Compare / set
                case (op)
                    3'b000: alu_out = (signed_x < signed_y)  ? 32'b1 : 32'b0; // SLT
                    3'b001: alu_out = (signed_x > signed_y)  ? 32'b1 : 32'b0; // SGT
                    3'b010: alu_out = (signed_x <= signed_y) ? 32'b1 : 32'b0; // SLE
                    3'b011: alu_out = (signed_x >= signed_y) ? 32'b1 : 32'b0; // SGE
                    3'b100: alu_out = (x == y)               ? 32'b1 : 32'b0; // SEQ
                    3'b101: alu_out = (x != y)               ? 32'b1 : 32'b0; // SNE
                    default: alu_out = 32'b0;
                endcase
            end

            3'b010: begin // Arithmetic (MUL/MULU deferred per Assignment 1B)
                case (op)
                    3'b000: alu_out = x + y; // ADD
                    3'b001: alu_out = x - y; // SUB
                    default: alu_out = 32'b0;
                endcase
            end

            3'b011: begin // Logic
                case (op)
                    3'b000: alu_out = x & y;       // AND
                    3'b001: alu_out = x | y;       // OR
                    3'b010: alu_out = ~x;          // NOT (rt unused)
                    3'b011: alu_out = ~(x|y);    // NOR
                    3'b100: alu_out = x ^ y;       // XOR
                    default: alu_out = 32'b0;
                endcase
            end

            3'b100: begin // Shift (using lower 5 bits of y for shift amount)
                case (op)
                    3'b000: alu_out = x << y[4:0];                    // SLL
                    3'b001: alu_out = x >> y[4:0];                    // SRL
                    3'b010: alu_out = $unsigned(signed_x >>> y[4:0]); // SRA
                    default: alu_out = 32'b0;
                endcase
            end

            default: alu_out = 32'b0;
        endcase
    end
endmodule
