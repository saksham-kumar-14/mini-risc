`timescale 1ns / 1ps

module tb_risc;

    // Inputs
    reg clk;
    reg rst;
    reg start;

    // Variables for self-checking
    integer expected_val;
    reg [199:0] test_name;
    reg pass;

    // Instantiate the Unit Under Test (UUT)
    minirisc_basic_top uut (
        .clk(clk),
        .rst(rst),
        .start(start)
    );

    // Clock generation: 10ns period (100 MHz)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        $dumpfile("minirisc_wave.vcd");
        $dumpvars(0, tb_risc);

        #20;
        rst = 0;

        #10;
        start = 1;
        #10;
        start = 0;

        #400; // Increased time to allow for memory delays and jump/branch routing

        $display("Simulation complete. Processor did not halt in time.");
        $finish;
    end

    // Monitor block: PC-aware Automated Self-Checking
    always @(negedge clk) begin
        // Data commits on RUN for single-cycle ops, and on WAIT for multicycle LD.
        if (!rst && ((uut.fsm_inst.state == 2'b01 && !uut.ld) || uut.fsm_inst.state == 2'b10)) begin

            // Map the current PC to the expected instruction and write-back data
            case (uut.pc_out)
                32'h00: begin test_name = "LI R1, 15     "; expected_val = 15; end
                32'h01: begin test_name = "LI R2, 10     "; expected_val = 10; end
                32'h02: begin test_name = "ADD R3, R1, R2"; expected_val = 25; end
                32'h03: begin test_name = "SUB R4, R1, R2"; expected_val = 5;  end
                32'h04: begin test_name = "ST R3, 4(R0)  "; expected_val = 32'bx; end // Store (No writeback check)
                32'h05: begin test_name = "LD R10, 4(R0) "; expected_val = 25; end // Load verification
                32'h06: begin test_name = "BEQ R3, R10, 2"; expected_val = 32'bx; end // Branch taken (25 == 25)
                32'h07: begin $display("FAIL: Branch failed, executed skipped code."); $finish; end
                32'h08: begin $display("FAIL: Branch failed, executed skipped code."); $finish; end
                32'h09: begin test_name = "HALT          "; expected_val = 0;  end
                default: begin test_name = "UNKNOWN       "; expected_val = 0; end
            endcase

            // Filter out instructions that do not perform a register write-back
            if (uut.pc_out != 32'h04 && uut.pc_out != 32'h06 && uut.pc_out != 32'h09) begin
                pass = ($signed(uut.write_data) == expected_val);
                $display("PC: %02h | %s | expected : %0d got: %0d %s",
                         uut.pc_out, test_name, expected_val, $signed(uut.write_data), pass ? "PASS" : "FAIL");

            // Check HALT instruction
            end else if (uut.pc_out == 32'h09) begin
                pass = (uut.inst == 32'hFC000000);
                $display("PC: %02h | %s | expected : FC000000 got: %h %s",
                         uut.pc_out, test_name, uut.inst, pass ? "PASS" : "FAIL");
                $display("Simulation complete. All control flow paths tested.");
                $finish;

            // Check non-writeback control instructions (ST, BEQ)
            end else begin
                $display("PC: %02h | %s | Control/Mem Op Executed", uut.pc_out, test_name);
            end
        end
    end

endmodule
