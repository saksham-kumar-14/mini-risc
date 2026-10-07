`timescale 1ns / 1ps

module tb_risc;

    // Inputs
    reg clk;
    reg rst;
    reg start;

    // Variables for self-checking
    integer inst_count;
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
        // Initialize Inputs
        clk = 0;
        rst = 1;
        start = 0;
        inst_count = 0;

        // Open dump file for waveform viewing (GTKWave/Vivado)
        $dumpfile("minirisc_wave.vcd");
        $dumpvars(0, tb_risc);

        // Hold reset high for 20ns
        #20;
        rst = 0;

        // Assert start signal to transition FSM from IDLE to RUN
        #10;
        start = 1;
        #10;
        start = 0;

        // Allow the simulation to run for enough cycles to complete the 10 instructions.
        #200;

        $display("Simulation complete.");
        $finish;
    end

    // Monitor block: Automated self-checking assertions
    // Triggers on the falling edge to read stable values just before the registers update.
    always @(negedge clk) begin
        if (!rst && uut.fsm_inst.state == 2'b01) begin // Only check during RUN state

            // Map the execution sequence to the expected data result
            case (inst_count)
                0: begin test_name = "ADDI R1, R0, 10"; expected_val = 10; end
                1: begin test_name = "ADDI R2, R0, 5 "; expected_val = 5;  end
                2: begin test_name = "ADD R3, R1, R2 "; expected_val = 15; end
                3: begin test_name = "SUB R4, R1, R2 "; expected_val = 5;  end
                4: begin test_name = "AND R5, R1, R3 "; expected_val = 10; end
                5: begin test_name = "ADDI R7, R0, 2 "; expected_val = 2;  end
                6: begin test_name = "SLL R6, R2, R7 "; expected_val = 20; end
                7: begin test_name = "SLT R8, R4, R3 "; expected_val = 1;  end
                8: begin test_name = "ADD R0, R1, R2 "; expected_val = 15; end
                9: begin test_name = "HALT           "; expected_val = 0;  end
                default: begin test_name = "UNKNOWN"; expected_val = 0; end
            endcase

            // Check standard arithmetic/logic writes (Instructions 0-8)
            if (inst_count < 9) begin
                pass = ($signed(uut.write_data) == expected_val);
                $display("PC: %h | %s | expected : %0d got: %0d %s",
                         uut.pc_out, test_name, expected_val, $signed(uut.write_data), pass ? "PASS" : "FAIL");

                // Specifically flag the R0 protection test
                if (inst_count == 8 && uut.reg_wr && uut.rd_addr_final == 4'b0000) begin
                    $display("  -> ATTEMPTED WRITE TO R0 DETECTED. Hardware must ignore.");
                end

            // Check HALT instruction (Instruction 9)
            end else if (inst_count == 9) begin
                pass = (uut.inst == 32'hFC000000);
                $display("PC: %h | %s | expected : FC000000 got: %h %s",
                         uut.pc_out, test_name, uut.inst, pass ? "PASS" : "FAIL");
            end

            inst_count = inst_count + 1;
        end
    end

endmodule
