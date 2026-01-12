`timescale 1ns / 1ps

module packet_buffer_fifo #(
    parameter DEPTH  = 2048,
    parameter ADDR_W = 11
)(
    input  wire        clk,
    input  wire        rst_n,


    input  wire        wr_valid, //This byte is valid
    input  wire [7:0]  wr_data,
    input  wire        wr_last,  //This is the last byte of the packet


    input  wire        pkt_ready_to_send, //TCAM lookup and action decision are DONE. You can now send the packet


    output reg  [7:0]  rd_data,  //Output byte
    output reg         rd_valid, //Output byte is valid
    output reg         rd_last   //End of packet
);


    reg [7:0] mem [0:DEPTH-1];  //stores packet bytes
    reg       mem_last [0:DEPTH-1];  //stores packet boundary information


    reg [ADDR_W-1:0] wr_ptr;   //Where to write next byte
    reg [ADDR_W-1:0] rd_ptr;   //Where to read next byte

    reg [ADDR_W-1:0] pkt_start_ptr;
    reg [ADDR_W-1:0] pkt_end_ptr;


    // FSM   MAC → COLLECT → HOLD → RELEASE

    localparam COLLECT = 2'd0,  //Receive packet from MAC
               HOLD    = 2'd1,  //Packet stored, waiting for TCAM
               RELEASE = 2'd2;  //Send packet 

    reg [1:0] state;


    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_valid) begin
            mem[wr_ptr]      <= wr_data;
            mem_last[wr_ptr] <= wr_last;
            wr_ptr <= wr_ptr + 1;

            if (wr_last)
                pkt_end_ptr <= wr_ptr;
        end
    end


    always @(posedge clk) begin
        if (!rst_n) begin
            state <= COLLECT;
            rd_ptr <= 0;
            rd_valid <= 0;
            rd_last <= 0;
            pkt_start_ptr <= 0;
        end else begin
            rd_valid <= 0;
            rd_last  <= 0;

            case (state)


                COLLECT: begin
                    if (wr_valid && wr_last) begin
                        state <= HOLD;
                    end
                end


                HOLD: begin
                    if (pkt_ready_to_send) begin
                        rd_ptr <= pkt_start_ptr;
                        state <= RELEASE;
                    end
                end


                RELEASE: begin
                    rd_data  <= mem[rd_ptr];
                    rd_last  <= mem_last[rd_ptr];
                    rd_valid <= 1;

                    if (mem_last[rd_ptr]) begin
                        pkt_start_ptr <= rd_ptr + 1;
                        state <= COLLECT;
                    end

                    rd_ptr <= rd_ptr + 1;
                end

            endcase
        end
    end

endmodule
