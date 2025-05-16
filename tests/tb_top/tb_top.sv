`timescale 1ns / 1ps
`include "top.sv"

module tb_top();

    // driving signals
    logic clk;
    logic rst_n;
    logic pA_stb_i, pA_cyc_i;
    logic [3:0] pA_we_i;
    logic [10:0] pA_addr_i;
    logic [31:0] pA_data_i;
    logic pA_stall_o, pA_ack_o;
    logic [31:0] pA_data_o;
    logic pB_stb_i, pB_cyc_i;
    logic [3:0] pB_we_i;
    logic [10:0] pB_addr_i;
    logic [31:0] pB_data_i;
    logic pB_stall_o, pB_ack_o;
    logic [31:0] pB_data_o;


    top dut(
        .clk(clk),
        .RST_N(rst_n),
        // port A
        .pA_stb_i(pA_stb_i),
        .pA_cyc_i(pA_cyc_i),
        .pA_we_i(pA_we_i),
        .pA_addr_i(pA_addr_i),
        .pA_data_i(pA_data_i),
        .pA_stall_o(pA_stall_o),
        .pA_ack_o(pA_ack_o),
        .pA_data_o(pA_data_o),
        // port B
        .pB_stb_i(pB_stb_i),
        .pB_cyc_i(pB_cyc_i),
        .pB_we_i(pB_we_i),
        .pB_addr_i(pB_addr_i),
        .pB_data_i(pB_data_i),

        .pB_stall_o(pB_stall_o),
        .pB_ack_o(pB_ack_o),
        .pB_data_o(pB_data_o)
    )

    // clock
    always begin
        #10 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpwars(0);
    end

    task reset();
        rst_n = 0;
        pA_stb_i = 0;
        pA_cyc_i = 0;
        pB_stb_i = 0;
        pB_cyc_i = 0;
        @(posedge clk);
        @(posedge clk);
        rst_n = 1;
    endtask

    task write_portA(input [10:0] addr, input [31:0] data);
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 4'b1111;
        pA_addr_i = addr;
        pA_data_i = data;
        @(posedge clk);
        wait (pA_ack_o);
        pA_stb_i = 0;
        pA_cyc_i = 0;
        pA_we_i = 0;
    endtask

    task write_portB(input [10:0] addr, input [31:0] data);
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 4'b1111;
        pB_addr_i = addr;
        pB_data_i = data;
        @(posedge clk);
        wait (pB_ack_o);
        pB_stb_i = 0;
        pB_cyc_i = 0;
        pB_we_i = 0;
    endtask

    task read_portA(input [10:0] addr, output [31:0] data);
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 0;
        pA_addr_i = addr;
        @(posedge clk);
        wait (pA_ack_o);
        data = pA_data_o;
        pA_stb_i = 0;
        pA_cyc_i = 0;
    endtask

    task read_portB(input [10:0] addr, output [31:0] data);
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 0;
        pB_addr_i = addr;
        @(posedge clk);
        wait (pB_ack_o);
        data = pB_data_o;
        pB_stb_i = 0;
        pB_cyc_i = 0;
    endtask

    initial begin
    clk = 0;
    reset();

    $display("Writing to RAM0 via Port A (addr 0x00)");
    write_portA(11'b000_0000_0000, 32'hDEADBEEF);

    $display("Writing to RAM1 via Port B (addr 0x400)");
    write_portB(11'b100_0000_0000, 32'hCAFEBABE);

    #10;

    logic [31:0] read_val_A, read_val_B;

    $display("Reading back via Port A (addr 0x00)");
    read_portA(11'b000_0000_0000, read_val_A);
    $display("Port A read value: 0x%h", read_val_A);

    $display("Reading back via Port B (addr 0x400)");
    read_portB(11'b100_0000_0000, read_val_B);
    $display("Port B read value: 0x%h", read_val_B);

    // Add more reads/writes here to verify contention or overlapping access

    #20 $finish;
end



endmodule
