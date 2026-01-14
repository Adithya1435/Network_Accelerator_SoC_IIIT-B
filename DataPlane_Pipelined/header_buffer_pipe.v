`timescale 1ns / 1ps3
module header_buffer_pipe_fifo #(
    parameter HEADER_BYTES = 192,
    parameter PTR_W = 8
)(
    input            clk,
    input            rst_n,

    // input            rx_valid,//frm mac  
    // input  [7:0]     rx_data,//mac
    // input            rx_last,//mac

    // output           rx_ready,//to mac tht its ready to receive pkt


    input       fifo_valid,// frm fifo
    input [7:0] fifo_data,
    input      fifo_last,
    output          fifo_ready,// to fifo

    output reg [8*HEADER_BYTES-1:0] header_flat,//op of header buf to the pipeline reg-09
    output reg [PTR_W:0]            header_len,//length (inc full payload) (packet length basicly)

    //output reg                      header_valid,//its a level, instead of the header_done pul +se (say a pkt stored in pipeline buffer still bein parsed, nxt pkt cannot enter the pipeine buffer, but its heaer dn pulse may be missed, so we need a level instead)
    output reg header_valid,
    input                           header_ready//comes frm the pipeline reg tellin its reeady to accept pkt
);

    reg [PTR_W:0] wr_ptr;//pts at the exact byte ur writin (only goes max till 191)
    reg           in_packet;//pkt has entered
    //reg           header_complete;

    integer i;

    //assign rx_ready = !header_valid; // stall MAC if header not consumed (ready to rec only whn header isnt valid)
    //assign rx_ready=1;
    assign fifo_ready= !header_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr          <= 0;//strt writin 1st byte
            header_len      <= 0;//total len reset
            //header_valid    <= 0;//to pipeline reg
            header_valid <= 0;//
            in_packet       <= 0;// no pkt
            for (i = 0; i < HEADER_BYTES; i = i + 1)
                header_flat[i*8 +: 8] <= 8'h00;//reset buf
        end else begin
          
            if (header_valid && header_ready)
                header_valid <= 1'b0;  // clear valid when downstream accepts

            if (fifo_valid && fifo_ready) begin// handshake to rec frm fifo
                if (!in_packet) begin// no pkt currently
                    in_packet       <= 1'b1;//new pkt
                    wr_ptr          <= 1;//nxt byte in nxt cycle
                    header_len      <= 1;//+1
                    header_valid <= (HEADER_BYTES == 1);//edge case
                    header_flat[0*8 +: 8] <= fifo_data;//1st byte write
                end else begin
                    header_len <= header_len + 1;//whn pkt alr there (irresp of wr_ptr < or > Header_bytes)

                    if (wr_ptr < HEADER_BYTES) begin
                        header_flat[wr_ptr*8 +: 8] <= fifo_data;// wri8 bytes
                        wr_ptr <= wr_ptr + 1;// nxt

                        if (wr_ptr == HEADER_BYTES-1)
                            header_valid <= 1'b1;//full header written
                    end

                    if (fifo_last && wr_ptr < HEADER_BYTES)
                        header_valid <= 1'b1;// if pkt is less thn 192 bytes
                end

                if (fifo_last)
                    in_packet <= 1'b0;// pkt over
            end

            // assert valid once header is complete
            //if (header_complete && !header_valid)
                //header_valid <= 1'b1;
        end
    end
endmodule

