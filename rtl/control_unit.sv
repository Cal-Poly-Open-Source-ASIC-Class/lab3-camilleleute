`timescale 1ns / 1ps

module control_unit (
    input logic clk,
    input logic RST,

    // from port A
    input logic pA_stb,
    input logic pA_cyc,
    input logic pA_CS, 

    // from port B
    input logic pB_stb,
    input logic pB_cyc,
    input logic pB_CS, 
    
    // outputs
    output logic sel0,
    output logic sel1,

    output logic pA_stall,
    output logic pB_stall,
    
    output logic EN0,
    output logic EN1,

    output logic pA_ack,
    output logic pB_ack,

    output logic reset
);

logic port_priority;
logic pA_req;
logic pB_req;
 

always_comb begin
    pA_req = pA_cyc && pA_stb;
    pB_req = pB_cyc && pB_stb;
end

always_ff @(posedge clk or negedge RST) begin
    if (!RST) begin
        reset <= 1;
        port_priority <= 0;
    end else begin
        reset <= 0;
        if (pA_req && pB_req && (pA_CS == pB_CS)) begin
            port_priority <= ~port_priority;
        end
    end 
end

always_comb begin
    // reset signals to 0
    sel0 = 0;
    sel1 = 0;
    pA_stall = 0;
    pB_stall  = 0;
    EN0  = 0;
    EN1  = 0;
    pA_ack = 0;
    pB_ack = 0;

    if (pA_req && pB_req) begin
        if (pA_CS != pB_CS) begin // not accessing same RAM, give ports what they want
                sel0 = pA_CS;
                EN0 = 1;
                pA_ack = 1;

                sel1 = pB_CS;
                EN1 = 1;
                pB_ack = 1;
        end else begin // accessing the same RAM
            pA_stall = port_priority;
            pB_stall = ~port_priority;
            if (port_priority) begin
                // port B 
                if (pB_CS) begin
                sel1 = 1;
                EN1 = 1;
                end else begin
                    sel0 = 1;
                    EN0 = 1;
                end
                pB_ack = 1;
            end else begin
                if (pA_CS) begin
                        sel1 = 0;
                        EN1 = 1;
                    end else begin
                        sel0 = 0;
                        EN0 = 1;
                    end
                    pA_ack = 1;                
                end 
        end
    end else if (pA_req) begin
        if (pA_CS) begin
                sel1 = 0;
                EN1 = 1;
            end else begin
                sel0 = 0;
                EN0 = 1;
            end
            pA_ack = 1;
    end else if (pB_req) begin
        if (pB_CS) begin
                sel1 = 1;
                EN1 = 1;
            end else begin
                sel0 = 1;
                EN0 = 1;
            end
            pB_ack = 1;
    end
end

endmodule