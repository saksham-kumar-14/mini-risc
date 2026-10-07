`timescale 1ns / 1ps

module tb_risc;

    // Inputs
    reg clk;
    reg rst;
    reg start;

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

        // The Phase 4 program contains 10 instructions.
        // We will allow the simulation to run for enough cycles to complete them.
        // It will safely stop executing when it hits the HALT (FC000000) instruction.
        #200;

        $display("Simulation complete. Check waveform for detailed datapath behavior.");
        $finish;
    end

    // Monitor block: Prints the exact signals required by the assignment to the console[cite: 10, 11]
    // Triggers on the falling edge to read stable values just before the registers update.
    always @(negedge clk) begin
        if (!rst && uut.fsm_inst.state == 2'b01) begin // Only print during RUN state
            $display("Time: %0t | PC: %h | Inst: %h", $time, uut.pc_out, uut.inst);
            $display("  [Decode] rs_addr: %d, rt_addr: %d, rd_addr: %d | alu_src: %b, reg_wr: %b, alu_func: %b",
                     uut.rs_addr_final, uut.rt_addr_final, uut.rd_addr_final,
                     uut.alu_src, uut.reg_wr, uut.alu_func);
            $display("  [Regs]   rs_data: %d, rt_data: %d | imm_ext: %d",
                     $signed(uut.rs_data), $signed(uut.rt_data), $signed(uut.imm_ext));
            $display("  [ALU]    op_x: %d, op_y: %d -> result: %d",
                     $signed(uut.rs_data), $signed(uut.alu_y), $signed(uut.alu_out));
            $display("  [Write]  write_data: %d", $signed(uut.write_data));

            // Check for R0 write attempt (Requirement 10)
            if (uut.reg_wr && uut.rd_addr_final == 4'b0000) begin
                $display("  *** ATTEMPTED WRITE TO R0 DETECTED: Value %d. Hardware must ignore. ***", $signed(uut.write_data));
            end

            // Detect HALT opcode to gracefully stop the monitor
            if (uut.inst == 32'hFC000000) begin
                $display("  *** HALT INSTRUCTION REACHED ***");
            end

            $display("--------------------------------------------------------------------------------");
        end
    end

endmodule
