//`timescale 1ns / 1ps

module top (
    input logic clk,
    input logic RST_N,

    // port A
    input logic pA_stb_i,
    input logic pA_cyc_i,
    input logic [3:0] pA_we_i,
    input logic [10:0] pA_addr_i,
    input logic [31:0] pA_data_i,

    output logic pA_stall_o,
    output logic pA_ack_o,
    output logic [31:0] pA_data_o,

    // port B
    input logic pB_stb_i,
    input logic pB_cyc_i,
    input logic [3:0] pB_we_i,
    input logic [10:0] pB_addr_i,
    input logic [31:0] pB_data_i,

    output logic pB_stall_o,
    output logic pB_ack_o,
    output logic [31:0] pB_data_o
);

logic [3:0] WE0, WE1;
logic [31:0] Di0, Di1;
logic [31:0] Do0, Do1;
logic [10:0] A0, A1;
logic sel_0, sel_1;
logic EN_0, EN_1;
logic reset;
logic pA_past_CS, pB_past_CS;

// Registers to store current cycle values for later reference
logic [31:0] pA_data_reg, pB_data_reg;
logic [3:0] pA_we_reg, pB_we_reg;

// Registers to store previous cycle values
logic [31:0] pA_prev_data_i, pB_prev_data_i;
logic [3:0] pA_prev_we, pB_prev_we;

// MUX to RAM0
always_comb begin
    if (sel_0 == 1'b0) begin
        // port A to RAM0
        WE0 = pA_we_i;
        Di0 = pA_data_i;
        A0 = pA_addr_i;
    end else begin
        // port B to RAM0
        WE0 = pB_we_i;
        Di0 = pB_data_i;
        A0 = pB_addr_i;
    end
end

// MUX to RAM1
always_comb begin
    if (sel_1 == 1'b0) begin
        // port A to RAM1
        WE1 = pA_we_i;
        Di1 = pA_data_i;
        A1 = pA_addr_i;
    end else begin
        // port B to RAM1
        WE1 = pB_we_i;
        Di1 = pB_data_i;
        A1 = pB_addr_i;
    end
end

control_unit controller(
    .clk(clk),
    .RST(RST_N),
    .pA_stb(pA_stb_i),
    .pA_cyc(pA_cyc_i),
    .pA_CS(pA_addr_i[10]), 

    // from port B
    .pB_stb(pB_stb_i),
    .pB_cyc(pB_cyc_i),
    .pB_CS(pB_addr_i[10]), 
    
    // outputs
    .sel0(sel_0),
    .sel1(sel_1),

    .pA_stall(pA_stall_o),
    .pB_stall(pB_stall_o),
    
    .EN0(EN_0),
    .EN1(EN_1),

    .pA_ack(pA_ack_o),
    .pB_ack(pB_ack_o),

    .pA_past_CS(pA_past_CS),
    .pB_past_CS(pB_past_CS),

    .reset(reset)
);

DFFRAM256x32 RAM0(
    .CLK(clk),
    .WE0(WE0),
    .EN0(EN_0),
    .Di0(Di0),
    .Do0(Do0),
    .A0(A0[9:2])
);

DFFRAM256x32 RAM1(
    .CLK(clk),
    .WE0(WE1),
    .EN0(EN_1),
    .Di0(Di1),
    .Do0(Do1),
    .A0(A1[9:2])
);

// MUX from RAM0 & RAM1
always_comb begin
    // Defaults
    pA_data_o = 32'b0;
    pB_data_o = 32'b0;

    // For Port A
    if (!pA_past_CS && pA_ack_o) begin
        pA_data_o = Do0;
    end else if (pA_past_CS && pA_ack_o) begin
        pA_data_o = Do1;
    end

    // For Port B
    if (!pB_past_CS && pB_ack_o) begin
        pB_data_o = Do0;
    end else if (pB_past_CS && pB_ack_o) begin
        pB_data_o = Do1;
    end

    // Handle write operations - use the proper previous cycle values
    if (pA_prev_we != 0 && pA_ack_o) begin
        pA_data_o = pA_prev_data_i;
    end

    if (pB_prev_we != 0 && pB_ack_o) begin
        pB_data_o = pB_prev_data_i;
    end
end

// Properly capture values in a two-stage pipeline to get proper "previous" values
always_ff @(posedge clk or negedge RST_N) begin
    if (!RST_N) begin
        // Reset all registers when reset is active
        pA_data_reg <= 32'b0;
        pB_data_reg <= 32'b0;
        pA_we_reg <= 4'b0;
        pB_we_reg <= 4'b0;
        pA_prev_data_i <= 32'b0;
        pB_prev_data_i <= 32'b0;
        pA_prev_we <= 4'b0;
        pB_prev_we <= 4'b0;
    end else begin
        // Stage 1: Current inputs -> registers
        pA_data_reg <= pA_data_i;
        pB_data_reg <= pB_data_i;
        pA_we_reg <= pA_we_i;
        pB_we_reg <= pB_we_i;
        
        // Stage 2: Registers -> previous value registers
        pA_prev_data_i <= pA_data_reg;
        pB_prev_data_i <= pB_data_reg;
        pA_prev_we <= pA_we_reg;
        pB_prev_we <= pB_we_reg;
        
    end
end

endmodule