`timescale 1ns / 1ps

module control_fsm (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire halt_inst,      // Asserted by decoder on HALT or illegal opcode
    input  wire is_multicycle,  // Asserted by decoder for LD (takes 2 cycles)

    output reg  pc_enable,
    output reg  ic_enable,
    output reg  sys_force_0     // Forces next_pc to 0
);

    // State encoding
    localparam IDLE = 2'b00;
    localparam RUN  = 2'b01;
    localparam WAIT = 2'b10;
    localparam DONE = 2'b11;

    reg [1:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else     state <= next_state;
    end

    always @(*) begin
        // Default outputs
        next_state  = state;
        pc_enable   = 1'b1;
        ic_enable   = 1'b1;
        sys_force_0 = 1'b0;

        case (state)
            IDLE: begin
                sys_force_0 = 1'b1; // pc_src overridden to 11
                if (start) next_state = RUN;
            end

            RUN: begin
                if (halt_inst) begin
                    next_state = DONE;
                end else if (is_multicycle) begin
                    next_state = WAIT;
                    pc_enable  = 1'b0;
                    ic_enable  = 1'b0;
                end
            end

            WAIT: begin
                // Basic single-cycle stall (sufficient for LD).
                // Multi-cycle multiplier will replace this with a halt_period counter later.
                next_state = RUN;
                pc_enable  = 1'b1;
                ic_enable  = 1'b1;
            end

            DONE: begin
                pc_enable = 1'b0;
                ic_enable = 1'b0;
            end

            default: next_state = IDLE;
        endcase
    end
endmodule
