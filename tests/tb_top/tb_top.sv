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
    );

    // clock
    always begin
        #10 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0);
    end

    initial begin
        #500; 
        $display("ERROR: Simulation timeout reached.");
        $finish;
    end

    task reset();
        rst_n = 0;
        pA_stb_i = 0;
        pA_cyc_i = 0;
        pA_we_i = 0;
        pA_addr_i = 0;
        pA_data_i = 0;
        pB_stb_i = 0;
        pB_cyc_i = 0;
        pB_we_i = 0;
        pB_addr_i = 0;
        pB_data_i = 0;
        repeat(2)@(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    task write_portA(input [10:0] addr, input [31:0] data);
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 4'b1111;
        pA_addr_i = addr;
        pA_data_i = data;

        @(posedge clk);
       

        pA_stb_i = 0;
        pA_cyc_i = 0;
        pA_we_i = 0;
        pA_data_i = '0;
        @(posedge clk);
    endtask

    task write_portB(input [10:0] addr, input [31:0] data);
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 4'b1111;
        pB_addr_i = addr;
        pB_data_i = data;
        // Wait until not stalled
        do begin
            @(posedge clk);
        end while (pB_stall_o);
        
        // Wait for ack
        while (!pB_ack_o) @(posedge clk);

        pB_stb_i = 0;
        pB_cyc_i = 0;
        pB_we_i = 0;
        pB_data_i = '0;

    endtask

    task read_portA(input [10:0] addr, output [31:0] data);
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 0;
        pA_addr_i = addr;
        pA_data_i = '0;
        do begin
            @(posedge clk);
        end while (pA_stall_o);
        
        // Wait for ack
        while (!pA_ack_o) @(posedge clk);
        data = pA_data_o;

        pA_stb_i = 0;
        pA_cyc_i = 0;
    endtask

    task read_portB(input [10:0] addr, output [31:0] data);
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 0;
        pB_addr_i = addr;
        pB_data_i = '0;
       // Wait until not stalled
        do begin
            @(posedge clk);
        end while (pB_stall_o);
        
        // Wait for ack
        while (!pB_ack_o) @(posedge clk);
        data = pB_data_o;

        pB_stb_i = 0;
        pB_cyc_i = 0;
    endtask

    task sim_write(
        input [10:0] addrA, 
        input [31:0] dataA, 
        input [10:0] addrB, 
        input [31:0] dataB
    );
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 4'b1111;
        pA_addr_i = addrA;
        pA_data_i = dataA;
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 4'b1111;
        pB_addr_i = addrB;
        pB_data_i = dataB;

        // Wait until not stalled
        //do @(posedge clk); while (pA_stall_o || pB_stall_o);
        @(posedge clk)

        // Wait for both ACKs
        //while (!pA_ack_o || !pB_ack_o) @(posedge clk);

        pA_stb_i = 0;
        pA_cyc_i = 0;
        pA_we_i = 0;
        pB_stb_i = 0;
        pB_cyc_i = 0;
        pB_we_i = 0;
    endtask


    task sim_read(
        input [10:0] addrA, 
        input [10:0] addrB,
        output [31:0] dataA,
        output [31:0] dataB
    );
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 0;
        pA_addr_i = addrA;
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 0;
        pB_addr_i = addrB;
        pA_data_i = '0;
        pB_data_i = '0;

        // Wait until not stalled
        //do @(posedge clk); while (pA_stall_o || pB_stall_o);
        @(posedge clk)

        // Wait for both ACKs
        //while (!pA_ack_o || !pB_ack_o) @(posedge clk);

        dataA = pA_data_o;
        dataB = pB_data_o;

        pA_stb_i = 0;
        pA_cyc_i = 0;
        pB_stb_i = 0;
        pB_cyc_i = 0;
    endtask

    task same_ram_write(
        input [10:0] addrA, 
        input [31:0] dataA, 
        input [10:0] addrB, 
        input [31:0] dataB
    );
        logic [31:0] readA, readB;
        
        // Step 1: Submit both write requests simultaneously
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 4'b1111;
        pA_addr_i = addrA;
        pA_data_i = dataA;
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 4'b1111;
        pB_addr_i = addrB;
        pB_data_i = dataB;
        
        // Wait for a clock cycle and check state
        @(posedge clk);
        assert(pB_ack_o && pA_stall_o) else 
            $error("Expected port B to write while port A stalls, got: pB_ack=%b, pA_stall=%b", pB_ack_o, pA_stall_o);
            
        // Port B completes its write
        pB_data_i = '0;   
        @(posedge clk);
        
        // Now port A should get access for its write
        assert(pA_ack_o ) else 
            $error("Expected port A to write while port B read stalls, got: pA_ack=%b, pB_stall=%b", pA_ack_o, pB_stall_o);
        
    endtask

    task same_ram_read(
        input [10:0] addrA, 
        input [10:0] addrB, 
        output [31:0] readA,
        output [31:0] readB
    );
        
        // Step 1: Submit both read requests simultaneously
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 4'b0000;
        pA_addr_i = addrA;
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 4'b0000;
        pB_addr_i = addrB;
        pA_data_i = '0;
        pB_data_i = '0;
        
        // Wait for a clock cycle and check state
        @(posedge clk);
        assert(pB_ack_o && pA_stall_o) else 
            $error("Expected port B to read while port A stalls, got: pB_ack=%b, pA_stall=%b", pB_ack_o, pA_stall_o);
            
        // Port B completes its read
        readB = pB_data_o;   
        @(posedge clk);
        
        // Now port A should get access for its read
        assert(pA_ack_o) else 
            $error("Expected port A to read while port B read stalls, got: pA_ack=%b, pB_stall=%b", pA_ack_o, pB_stall_o);
        
        // Port A completes its write and issues a read
        readA = pA_data_o;
        @(posedge clk);
        
    endtask


    task same_ram_access_read(
        input [10:0] addrA, 
        input [10:0] addrB, 
        output [31:0] readA,
        output [31:0] readB
    );
        pA_stb_i = 1;
        pA_cyc_i = 1;
        pA_we_i = 4'b0000;
        pA_addr_i = addrA;
        pB_stb_i = 1;
        pB_cyc_i = 1;
        pB_we_i = 4'b0000;
        pB_addr_i = addrB;

        // Wait until not stalled
        //do @(posedge clk); while (pA_stall_o || pB_stall_o);
        repeat(2) @(posedge clk)

        // Wait for both ACKs
        //while (!pA_ack_o || !pB_ack_o) @(posedge clk);
        readA = pA_data_o;
        readB = pB_data_o;

        pA_stb_i = 0;
        pA_cyc_i = 0;
        pA_we_i = 0;
        pB_stb_i = 0;
        pB_cyc_i = 0;
        pB_we_i = 0;
    endtask

    initial begin
        logic [31:0] read_data_A;
        logic [31:0] read_data_B;

        reset();


        // test 1: basic write and reads on A
        $display("\nTest 1: Basic write/read on port A - RAM0");
        write_portA(11'h000, 32'hA5A5A5A5);
        // read_portA(11'h000, read_data_A);
        // assert((read_data_A === 32'hA5A5A5A5) && pA_ack_o)
        //     $display("PASS: Port A read back correct data from RAM0: %h", read_data_A);
        // else
        //     $error("FAIL: Port A read incorrect data from RAM0: %h, expected: %h", read_data_A, 32'hA5A5A5A5);

        // // Test 2: Basic write and read operations on port A - RAM1
        // $display("\nTest 2: Basic write/read on port A - RAM1");
        // write_portA(11'h400, 32'h5A5A5A5A);
        // read_portA(11'h400, read_data_A);
        // assert((read_data_A === 32'h5A5A5A5A) && pA_ack_o)
        //     $display("PASS: Port A read back correct data from RAM1: %h", read_data_A);
        // else
        //     $error("FAIL: Port A read incorrect data from RAM1: %h, expected: %h", read_data_A, 32'h5A5A5A5A);

        // // Test 3: Basic write and read operations on port B - RAM0
        // $display("\nTest 3: Basic write/read on port B - RAM0");
        // write_portB(11'h000, 32'hBBBBBBBB);
        // read_portB(11'h000, read_data_B);
        // assert((read_data_B === 32'hBBBBBBBB) && pB_ack_o)
        //     $display("PASS: Port B read back correct data from RAM0: %h", read_data_B);
        // else
        //     $error("FAIL: Port B read incorrect data from RAM0: %h, expected: %h", read_data_B, 32'hBBBBBBBB);
        
        // // Test 4: Basic write and read operations on port B - RAM1
        // $display("\nTest 4: Basic write/read on port B - RAM1");
        // write_portB(11'h404, 32'hCCCCCCCC);
        // read_portB(11'h404, read_data_B);
        // assert((read_data_B === 32'hCCCCCCCC) && pB_ack_o)
        //     $display("PASS: Port B read back correct data from RAM1: %h", read_data_B);
        // else
        //     $error("FAIL: Port B read incorrect data from RAM1: %h, expected: %h", read_data_B, 32'hCCCCCCCC);



        // // Test 5: Simultaneous write & read to different RAMs
        // $display("\nTest 5: Simultaneous write to different RAMs");
        // sim_write(11'h008, 32'hDEADBEEF, 11'h408, 32'hCAFEBABE);
        
        // sim_read(11'h008, 11'h408, read_data_A, read_data_B);
        
        // assert(read_data_A === 32'hDEADBEEF)
        //     $display("PASS: Port A wrote correct data to RAM0: %h", read_data_A);
        // else
        //     $error("FAIL: Port A wrote incorrect data to RAM0: %h, expected: %h", read_data_A, 32'hDEADBEEF);
            
        // assert(read_data_B === 32'hCAFEBABE)
        //     $display("PASS: Port B wrote correct data to RAM1: %h", read_data_B);
        // else
        //     $error("FAIL: Port B wrote incorrect data to RAM1: %h, expected: %h", read_data_B, 32'hCAFEBABE);

        // // Test 6: write from one port, read fomr the other
        // $display("\nTest 6: write from one port, read fomr the other");
        // write_portA(11'h00c, 32'h67676767);
        // read_portB(11'h404, read_data_B);
        // assert(read_data_B === 32'hCCCCCCCC)
        //     $display("PASS: Port A wrote correct data to RAM0 & Port B read correctly: %h", read_data_B);
        // else
        //     $error("FAIL: Port A wrote incorrect data to RAM0: %h, expected: %h", read_data_B,32'hCCCCCCCC);


        // // Test 7: Simultaneous write and read to RAM0
        // $display("\nTest 7: Simultaneous write and read to RAM0");
        // same_ram_write(11'h010, 32'h12345678, 11'h014, 32'h87654321);
        // same_ram_read(11'h010, 11'h014, read_data_A, read_data_B);
            
        //     assert(read_data_B ===  32'h87654321)
        //         $display("PASS: Port B wrote correct data to RAM1: %h", read_data_B);
        //     else
        //         $error("FAIL: Port B wrote incorrect data to RAM1: %h, expected: %h", read_data_B,  32'h87654321);

        //         assert(read_data_A ===  32'h12345678)
        //         $display("PASS: Port A wrote correct data to RAM0: %h", read_data_A);
        //     else
        //         $error("FAIL: Port A wrote incorrect data to RAM0: %h, expected: %h", read_data_A, 32'h12345678);
                


        
    $finish;
    end

endmodule
