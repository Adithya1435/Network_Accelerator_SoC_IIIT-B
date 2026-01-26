`timescale 1ns / 1ps

module packet_fifo_upper #(
    parameter DEPTH  = 512,
    parameter ADDR_W = $clog2(DEPTH),
    parameter ACTION_W = 64
)(
    input  wire clk,
    input  wire rst_n,

    // write side (frm fifo in bottom)
    input  wire       wr_valid,
    input  wire [7:0] wr_data,
    input  wire       wr_last,
    output wire       wr_ready,

    // read side
    output reg        rd_valid,
    output reg [7:0]  rd_data,
    output reg        rd_last,
    input  wire       rd_ready,

    // action control
    input  wire              allow_drain,
    input  wire [ACTION_W-1:0] action_in,

    // outputs
    output reg               pkt_sop,
    output reg [ACTION_W-1:0] action_out
);
//data storing
    reg [7:0] mem      [0:DEPTH-1];
    reg       mem_last [0:DEPTH-1];

    reg [ADDR_W:0] wr_ptr, rd_ptr, count;

    assign wr_ready = (count < DEPTH);

    wire write_en = wr_valid && wr_ready;
    wire read_en  = rd_valid && rd_ready;

  //pkt end fifo
    reg [ADDR_W:0] pkt_end_fifo [0:DEPTH-1];
    reg [ADDR_W:0] pkt_end_wr_ptr, pkt_end_rd_ptr;

  //fifo for action ownership
    reg [ACTION_W-1:0] action_fifo [0:DEPTH-1];
    reg [ADDR_W:0]     action_wr_ptr, action_rd_ptr;

 //drain ctrl
    reg [ADDR_W:0] drain_end_ptr;
    reg draining;

    wire pkt_available = (pkt_end_rd_ptr != pkt_end_wr_ptr);
    wire act_available = (action_rd_ptr != action_wr_ptr);

    wire start_drain =
        !draining &&
        pkt_available &&
        act_available;

 //write side
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            pkt_end_wr_ptr <= 0;
        end else if (write_en) begin
            mem[wr_ptr[ADDR_W-1:0]]      <= wr_data;
            mem_last[wr_ptr[ADDR_W-1:0]] <= wr_last;

            if (wr_last) begin
                pkt_end_fifo[pkt_end_wr_ptr] <= wr_ptr;
                pkt_end_wr_ptr <= pkt_end_wr_ptr + 1;
            end

            wr_ptr <= wr_ptr + 1;
        end
    end

 //action queue
    always @(posedge clk) begin
        if (!rst_n) begin
            action_wr_ptr <= 0;
        end else if (allow_drain) begin
            action_fifo[action_wr_ptr] <= action_in;
            action_wr_ptr <= action_wr_ptr + 1;
        end
    end

 //reading
    always @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            rd_valid <= 0;
            rd_last <= 0;
            draining <= 0;
            pkt_sop <= 0;
            pkt_end_rd_ptr <= 0;
            action_rd_ptr <= 0;
            action_out <= 0;
        end else begin
            pkt_sop <= 0;

            if (start_drain) begin
                draining <= 1'b1;
                drain_end_ptr <= pkt_end_fifo[pkt_end_rd_ptr];
                pkt_end_rd_ptr <= pkt_end_rd_ptr + 1;

                action_out <= action_fifo[action_rd_ptr];
                action_rd_ptr <= action_rd_ptr + 1;

                pkt_sop <= 1'b1;
            end

            if (draining) begin
                rd_valid <= 1'b1;
                rd_data  <= mem[rd_ptr[ADDR_W-1:0]];
                rd_last  <= mem_last[rd_ptr[ADDR_W-1:0]];

                if (rd_ready) begin
                    if (rd_ptr == drain_end_ptr)
                        draining <= 1'b0;

                    rd_ptr <= rd_ptr + 1;
                end
            end else begin
                rd_valid <= 1'b0;
            end
        end
    end

//counting
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({write_en, read_en})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: ;
            endcase
        end
    end

endmodule
