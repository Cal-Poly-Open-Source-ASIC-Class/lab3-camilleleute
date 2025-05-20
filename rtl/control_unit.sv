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
logic pA_req, pB_req;
logic pA_next_ACK, pB_next_ACK;

typedef enum logic [1:0] { 
    IDLE = 2'b00,
    PORT_A = 2'b01,
    PORT_B = 2'b10,
    PORT_A_B = 2'b11
} state_t;

 state_t PS, NS;

always_comb begin
    pA_req = pA_cyc && pA_stb;
    pB_req = pB_cyc && pB_stb;
end

always_ff @(posedge clk or negedge RST) begin
    if (!RST) begin
        PS <= IDLE;
        reset <= 1;
        port_priority <= 0;
    end else begin
        reset <= 0;
        PS <= NS;
        pA_ack <= pA_next_ACK;
        pB_ack <= pB_next_ACK;
        if (pA_req && pB_req && (pA_CS == pB_CS)) begin
            port_priority <= ~port_priority;
        end
    end 
end

function void set_select_B (
    input logic pB_CS,
    output logic sel0,
    output logic sel1,
    output logic EN0,
    output logic EN1);

    if (pB_CS) begin
        sel1 = 1;
        EN1 = 1;
        sel0 = 0;
        EN0 = 0;
    end else begin
        sel0 = 1;
        EN0 = 1;
        sel1 = 0;
        EN1 = 0;
    end
endfunction

function void set_select_A (
    input logic pA_CS,
    output logic sel0,
    output logic sel1,
    output logic EN0,
    output logic EN1);

    if (pA_CS) begin
        sel1 = 0;
        EN1 = 1;
        sel0 = 0;
        EN0 = 0;
    end else begin
        sel0 = 0;
        EN0 = 1;
        sel1 = 0;
        EN1 = 0;
    end
endfunction

function void state_select(
    input logic pA_req,
    input logic pB_req,
    input logic pA_CS,
    input logic pB_CS,
    output logic sel0,
    output logic sel1,
    output logic EN0,
    output logic EN1,
    output logic pA_stall,
    output logic pB_stall,
    output logic [1:0] NS
    );
    if (pA_req && pB_req) begin
        if (pA_CS != pB_CS) begin // not accessing same RAM, give ports what they want
            sel0 = pA_CS;
            EN0 = 1;
            sel1 = pB_CS;
            EN1 = 1;
            NS = PORT_A_B;
        end else begin // accessing the same RAM
            pA_stall = port_priority;
            pB_stall = ~port_priority;
            if (port_priority) begin
                // port B 
                set_select_B(pB_CS, sel0, sel1, EN0, EN1);
                NS = PORT_A;
            end else begin
                // port A
                set_select_A(pA_CS, sel0, sel1, EN0, EN1);
                NS = PORT_B;
            end
        end
    end else if (pB_req) begin  
        set_select_B(pB_CS, sel0, sel1, EN0, EN1);
        NS = PORT_B;
    end else if (pA_req) begin  
        set_select_A(pA_CS, sel0, sel1, EN0, EN1);
        NS = PORT_A;
    end else begin
        sel0 = 0;
        sel1 = 0;
        EN0 = 0;
        EN1 = 0;
        NS = IDLE;
    end
endfunction

always_comb begin
    // reset signals to 0
    sel0 = 0;
    sel1 = 0;
    pA_stall = 0;
    pB_stall  = 0;
    EN0  = 0;
    EN1  = 0;
    pA_next_ACK = 0;
    pB_next_ACK = 0;
    NS = PS;

    case (PS) 
        IDLE: begin
            if (pA_req || pB_req) begin
                state_select(pA_req, pB_req, pA_CS, pB_CS, sel0, sel1, EN0, EN1, pA_stall, pB_stall, NS);
            end else begin
                NS = IDLE;
            end
        end
        PORT_A: begin
            pA_next_ACK = 1;                
            state_select(pA_req, pB_req, pA_CS, pB_CS, sel0, sel1, EN0, EN1, pA_stall, pB_stall, NS);

        end
        PORT_B: begin
            pB_next_ACK = 1;
            state_select(pA_req, pB_req, pA_CS, pB_CS, sel0, sel1, EN0, EN1, pA_stall, pB_stall, NS);
        end
        PORT_A_B: begin
            pA_next_ACK = 1;
            pB_next_ACK = 1;
            state_select(pA_req, pB_req, pA_CS, pB_CS, sel0, sel1, EN0, EN1, pA_stall, pB_stall, NS);
        end
        default: NS = IDLE;
    endcase
end

endmodule