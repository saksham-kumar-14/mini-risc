`timescale 1ns / 1ps

module minirisc_basic_top (
    input wire clk,
    input wire rst,
    input wire start
);

    // =========================================================================
    // 1. Interconnect Wires
    // =========================================================================

    // PC & Fetch
    wire [31:0] pc_out;
    wire [31:0] next_pc;
    wire [31:0] inc_pc;
    wire [31:0] inst;
    wire        pc_enable;
    wire        ic_enable;
    wire        sys_force_0;

    // Decoder Signals
    wire [1:0]  reg_dst;
    wire        hi_lo;
    wire        reg_wr;
    wire        alu_src;
    wire [5:0]  alu_func;
    wire        ld, st;
    wire [1:0]  reg_in;
    wire [1:0]  pc_src;
    wire        is_br;
    wire [2:0]  br_t;
    wire        frz;
    wire [2:0]  rt_sel;
    wire        halt_inst;

    // Register File & Writeback
    wire [3:0]  rs_addr_final;
    wire [3:0]  rt_addr_final;
    wire [3:0]  rd_addr_final;
    wire [31:0] rs_data;
    wire [31:0] rt_data;
    wire [31:0] write_data;

    // ALU & Immediates
    wire [31:0] imm_ext;
    wire [31:0] alu_y;
    wire [31:0] alu_out;
    wire        ovfl;

    // =========================================================================
    // 2. Control FSM
    // =========================================================================
    control_fsm fsm_inst (
        .clk           (clk),
        .rst           (rst),
        .start         (start),
        .halt_inst     (halt_inst),
        .is_multicycle (ld),         // LD is the only multicycle op for now
        .pc_enable     (pc_enable),
        .ic_enable     (ic_enable),
        .sys_force_0   (sys_force_0)
    );

    // =========================================================================
    // 3. Instruction Fetch (PC & BRAM)
    // =========================================================================
    pc_unit pc_inst (
        .clk       (clk),
        .rst       (rst),
        .pc_enable (pc_enable),
        .next_pc   (next_pc),
        .pc_out    (pc_out)
    );

    // Configured as a single-port ROM per the requirements[cite: 6]
    instruction_bram_rom fetch_bram_inst (
        .clka       (clk),
        .ena (ic_enable),
        .addra      (next_pc),
        .douta      (inst)
    );

    // =========================================================================
    // 4. Instruction Decode
    // =========================================================================
    instruction_decoder decoder_inst (
        .inst      (inst),
        .reg_dst   (reg_dst),
        .hi_lo     (hi_lo),
        .reg_wr    (reg_wr),
        .alu_src   (alu_src),
        .alu_func  (alu_func),
        .ld        (ld),
        .st        (st),
        .reg_in    (reg_in),
        .pc_src    (pc_src),
        .is_br     (is_br),
        .br_t      (br_t),
        .frz       (frz),
        .rt_sel    (rt_sel),
        .halt      (halt_inst)
    );

    // =========================================================================
    // 5. Register Address Multiplexing
    // =========================================================================

    // Force rs to R0 for instructions like LI, MFHI, BZ
    assign rs_addr_final = frz ? 4'b0000 : inst[19:16];

    // rt_sel multiplexer to feed the second read port
    reg [3:0] rt_addr_mux;
    always @(*) begin
        case (rt_sel)
            3'b000: rt_addr_mux = inst[14:11]; // Normal rt
            3'b001: rt_addr_mux = inst[24:21]; // rd (used for ST, branches)
            3'b010: rt_addr_mux = 4'b0000;     // R0 (used for MOVE)
            default: rt_addr_mux = 4'b0000;    // HI/LO (011, 100) deferred
        endcase
    end
    assign rt_addr_final = rt_addr_mux;

    // Destination register selection
    reg [3:0] rd_addr_mux;
    always @(*) begin
        case (reg_dst)
            2'b01: rd_addr_mux = inst[24:21]; // Normal rd destination
            2'b11: rd_addr_mux = 4'd15;       // R15 for JAL link register
            default: rd_addr_mux = 4'b0000;   // Unused or LO (deferred)
        endcase
    end
    assign rd_addr_final = rd_addr_mux;

    // =========================================================================
    // 6. Register File
    // =========================================================================
    reg_file reg_file_inst (
        .clk        (clk),
        .we         (reg_wr),
        .rs_addr    (rs_addr_final),
        .rt_addr    (rt_addr_final),
        .rd_addr    (rd_addr_final),
        .write_data (write_data),
        .rs_data    (rs_data),
        .rt_data    (rt_data)
    );

    // =========================================================================
    // 7. Execution (Immediate, Mux, ALU)
    // =========================================================================
    imm_ext imm_ext_inst (
        .imm_in   (inst[15:0]),
        .alu_src  (alu_src),
        .alu_unit (alu_func[5:3]),
        .imm_out  (imm_ext)
    );

    alu_mux alu_mux_inst (
        .rt_data (rt_data),
        .ext_imm (imm_ext),
        .alu_src (alu_src),
        .alu_y   (alu_y)
    );

    alu alu_inst (
        .x        (rs_data),
        .y        (alu_y),
        .alu_func (alu_func),
        .alu_out  (alu_out),
        .ovfl     (ovfl)
    );

    // =========================================================================
    // 8. Next Address Decoder (Branch/Jump Logic)
    // =========================================================================
    next_addr_dec nad_inst (
        .pc_out      (pc_out),
        .imm_ext     (imm_ext),
        .jta         (inst[25:0]),
        .rs_data     (rs_data),
        .rt_data     (rt_data),
        .pc_src      (pc_src),
        .is_br       (is_br),
        .br_t        (br_t),
        .ovfl        (ovfl),
        .sys_force_0 (sys_force_0),
        .next_pc     (next_pc),
        .inc_pc      (inc_pc)
    );

    // =========================================================================
    // 9. Data Memory & Write-Back Multiplexer
    // =========================================================================

    wire [31:0] mem_read_data;

    // Instantiate the Data BRAM
    data_bram_ram data_mem_inst (
        .clk  (clk),
        .we   (st),            // Store signal acts as write enable
        .addr (alu_out),       // ALU computes base + offset for effective-address
        .din  (rt_data),       // rt_sel dynamically routes the 'rd' field to rt_data for ST
        .dout (mem_read_data)  // Fed into the write-back mux for LD
    );

    // Memory write-back select
    reg [31:0] writeback_mux;
    always @(*) begin
        case (reg_in)
            2'b00: writeback_mux = mem_read_data; // Memory (LD)
            2'b01: writeback_mux = alu_out;       // ALU result
            2'b10: writeback_mux = inc_pc;        // PC + 1 (JAL)
            2'b11: writeback_mux = 32'b0;         // Zero
        endcase
    end

    assign write_data = writeback_mux;

endmodule
