`timescale 1ns / 1ps
module packet_fifo_upper #(
    parameter DEPTH  = 512,
    parameter ADDR_W = $clog2(DEPTH)
)(
    input  clk,
    input  rst_n,

   //frm lower fifo
    input        wr_valid,
    input  [7:0] wr_data,
    input        wr_last,
    output       wr_ready,

    //to rewrite mux
    output reg        rd_valid,
    output reg [7:0]  rd_data,
    output reg        rd_last,
    input             rd_ready,

   //frm action_drain_ctrl
    input             allow_drain,

    output reg        pkt_sop   // 1-cycle pulse at first byte
);

    //storage
    reg [7:0] mem      [0:DEPTH-1];
    reg       mem_last [0:DEPTH-1];

    reg [ADDR_W:0] wr_ptr;
    reg [ADDR_W:0] rd_ptr;
    reg [ADDR_W:0] count;

    assign wr_ready = (count < DEPTH);

    wire write_en = wr_valid && wr_ready;
    wire read_en  = rd_valid && rd_ready;

    //pkt boundary traacking
    reg [ADDR_W:0] pkt_end_ptr;
    reg [ADDR_W:0] drain_end_ptr;
    reg draining;

    //write
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr      <= 0;
            pkt_end_ptr <= 0;
        end else if (write_en) begin
            mem[wr_ptr[ADDR_W-1:0]]      <= wr_data;
            mem_last[wr_ptr[ADDR_W-1:0]] <= wr_last;

            if (wr_last)
                pkt_end_ptr <= wr_ptr;

            wr_ptr <= wr_ptr + 1;
        end
    end

   //read
    always @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr        <= 0;
            rd_valid      <= 0;
            rd_data       <= 0;
            rd_last       <= 0;
            draining      <= 0;
            drain_end_ptr <= 0;
            pkt_sop       <= 0;
        end else begin
            pkt_sop  <= 0;

            // start draining exactly one packet
            if (allow_drain && !draining && count != 0) begin
                draining      <= 1'b1;
                drain_end_ptr <= pkt_end_ptr;
                pkt_sop       <= 1'b1;  //strt of pkt
            end

            if (draining) begin
                rd_valid <= 1'b1;
                rd_data  <= mem[rd_ptr[ADDR_W-1:0]];
                rd_last  <= (rd_ptr == drain_end_ptr);

                if (rd_ready) begin
                    if (rd_ptr == drain_end_ptr) begin
                        // pkt finished
                        draining <= 1'b0;
                        rd_valid <= 1'b0;
                        rd_ptr   <= rd_ptr + 1;
                    end else begin
                        rd_ptr <= rd_ptr + 1;
                    end
                end
            end else begin
                rd_valid <= 1'b0;
            end
        end
    end

    //count
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({write_en, read_en})
                2'b10: if (count < DEPTH) count <= count + 1;
                2'b01: if (count > 0)     count <= count - 1;
                default: ;
            endcase
        end
    end

endmodule
