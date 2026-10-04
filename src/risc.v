module risc (
    input wire clk,
    input wire reset,
    output reg [31:0] pc
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'b0;
        end else begin
            pc <= pc + 4;
        end
    end

endmodule
