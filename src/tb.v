`timescale 1ns/1ps

module tb_risc;
    reg clk;
    reg reset;
    wire [31:0] pc;

    // Instantiate the processor
    risc uut (
        .clk(clk),
        .reset(reset),
        .pc(pc)
    );

    // Generate clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Dump waves
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_risc);

        // Test sequence
        reset = 1;
        #10 reset = 0;

        // Run for a few cycles
        #50;

        $finish;
    end
endmodule
