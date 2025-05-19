// 2 port dual RAM
`include "control_unit.sv"
`include "DFFRAM256x32.v"
`timescale 1ns / 1ps

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
logic [7:0] A0, A1;
logic sel_0, sel_1;
logic EN_0, EN_1;
logic reset;

// MUX to RAM0
always_comb begin
    if (!sel_0) begin
        // port A to RAM0
        WE0 = pA_we_i;
        Di0 = pA_data_i;
        A0 = pA_addr_i[9:2];
    end else begin
        // port B to RAM0
        WE0 = pB_we_i;
        Di0 = pB_data_i;
        A0 = pB_addr_i[9:2];
    end
end

// MUX to RAM1
always_comb begin
    if (!sel_1) begin
        // port A to RAM1
        WE1 = pA_we_i;
        Di1 = pA_data_i;
        A1 = pA_addr_i[9:2];
    end else begin
        // port B to RAM1
        WE1 = pB_we_i;
        Di1 = pB_data_i;
        A1 = pB_addr_i[9:2];
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

    .reset(reset)
);

DFFRAM256x32 RAM0(
        .CLK(clk),
        .WE0(WE0),
        .EN0(EN_0),
        .Di0(Di0),
        .Do0(Do0),
        .A0(A0)
);

DFFRAM256x32 RAM1(
        .CLK(clk),
        .WE0(WE1),
        .EN0(EN_1),
        .Di0(Di1),
        .Do0(Do1),
        .A0(A1)
);

// MUX from RAM0 & RAM1
always_comb begin
    // Defaults
    pA_data_o = 32'b0;
    pB_data_o = 32'b0;

    // For Port A
    if (!pA_addr_i[10] && (pA_we_i == 0) && pA_ack_o) begin
        pA_data_o = Do0;
    end else begin
        pA_data_o = Do1;
    end

    // For Port B
    if (!pB_addr_i[10] && (pB_we_i == 0) && pB_ack_o) begin
        pB_data_o = Do0;
    end else begin
        pB_data_o = Do1;
    end
end

endmodule