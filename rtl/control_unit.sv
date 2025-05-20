//`timescale 1ns / 1ps

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

    output logic pA_past_CS,
    output logic pB_past_CS,

    output logic reset
);

logic port_priority;
logic pA_req, pB_req;
logic pA_next_ACK, pB_next_ACK;

// Define the state encoding
localparam IDLE = 2'b00;
localparam PORT_A = 2'b01;
localparam PORT_B = 2'b10;
localparam PORT_A_B = 2'b11;

// State variables
logic [1:0] PS, NS;

always_comb begin
    pA_req = pA_cyc && pA_stb;
    pB_req = pB_cyc && pB_stb;
end

logic pA_int_CS, pB_int_CS;

always_ff @(posedge clk or negedge RST) begin
    if (!RST) begin
        PS <= IDLE;
        reset <= 1;
        port_priority <= 0;
        pA_past_CS <= 0;
        pB_past_CS <= 0;
    end else begin
        reset <= 0;
        PS <= NS;
        pA_past_CS <= pA_CS;
        pB_past_CS <= pB_CS;
        if (pA_req && pB_req && (pA_CS == pB_CS)) begin
            port_priority <= ~port_priority;
        end
    end 
end

// Helper functions implemented inline to simplify compilation
always_comb begin
    // reset signals to 0
    sel0 = 0;
    sel1 = 0;
    pA_stall = 0;
    pB_stall = 0;
    EN0 = 0;
    EN1 = 0;
    pA_ack = 0;
    pB_ack = 0;
    NS = PS;

    case (PS) 
        IDLE: begin
            // State computation logic
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
                        // Port B gets access
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
                        pB_stall = 0;
                        pA_stall = 1;
                        NS = PORT_B;
                    end else begin
                        // Port A gets access
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
                        pA_stall = 0;
                        pB_stall = 1;
                        NS = PORT_A;
                    end
                end
            end else if (pB_req) begin  
                // Only port B is active
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
                NS = PORT_B;
            end else if (pA_req) begin  
                // Only port A is active
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
                NS = PORT_A;
            end else begin
                pB_stall = 0;
                NS = IDLE;
            end
        end

        PORT_A: begin
            pA_ack = 1;
            
            // Same state logic as IDLE
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
                        // Port B gets access
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
                        pB_stall = 0;
                        pA_stall = 1;
                        NS = PORT_B;
                    end else begin
                        // Port A gets access
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
                        pA_stall = 0;
                        pB_stall = 1;
                        NS = PORT_A;
                    end
                end
            end else if (pB_req) begin  
                // Only port B is active
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
                NS = PORT_B;
            end else if (pA_req) begin  
                // Only port A is active
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
                NS = PORT_A;
            end else begin
                pB_stall = 0;
                NS = IDLE;
            end
        end

        PORT_B: begin
            pB_ack = 1;
            
            // Same state logic as IDLE
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
                        // Port B gets access
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
                        pB_stall = 0;
                        pA_stall = 1;
                        NS = PORT_B;
                    end else begin
                        // Port A gets access
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
                        pA_stall = 0;
                        pB_stall = 1;
                        NS = PORT_A;
                    end
                end
            end else if (pB_req) begin  
                // Only port B is active
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
                NS = PORT_B;
            end else if (pA_req) begin  
                // Only port A is active
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
                NS = PORT_A;
            end else begin
                pB_stall = 0;
                NS = IDLE;
            end
        end

        PORT_A_B: begin
            pA_ack = 1;
            pB_ack = 1;
            
            // Same state logic as IDLE
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
                        // Port B gets access
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
                        pB_stall = 0;
                        pA_stall = 1;
                        NS = PORT_B;
                    end else begin
                        // Port A gets access
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
                        pA_stall = 0;
                        pB_stall = 1;
                        NS = PORT_A;
                    end
                end
            end else if (pB_req) begin  
                // Only port B is active
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
                NS = PORT_B;
            end else if (pA_req) begin  
                // Only port A is active
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
                NS = PORT_A;
            end else begin
                pB_stall = 0;
                NS = IDLE;
            end
        end

        default: NS = IDLE;
    endcase
end

endmodule