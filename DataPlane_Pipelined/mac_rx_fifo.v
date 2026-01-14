`timescale 1ns / 1ps
module mac_rx_fifo #(
    parameter DEPTH = 16,               // must be >= 12, used 16
    parameter ADDR_W = 4                // log2(DEPTH)
)(
    input            clk,
    input            rst_n,

    // MAC side
    input            rx_valid,//frm mac
    input  [7:0]     rx_data,//"
    input            rx_last,//"
    output           rx_ready,// to mac

    // Header buffer side, similar signals to wht mac used to giv
    output reg       fifo_valid,
    output reg [7:0] fifo_data,
    output reg       fifo_last,
    input            fifo_ready
);

    // storage
    reg [7:0] data_mem [0:DEPTH-1];// might hv to flatten (the Entire FIFO)
    reg       last_mem [0:DEPTH-1];//tells which byte is the last of the pkt (if any)

    reg [ADDR_W:0] wr_ptr;// the addr of byte to be written to by the mac
    reg [ADDR_W:0] rd_ptr;//adddr of byte to be read byt the header buff
    reg [ADDR_W:0] count;//how full s the fifo

    integer i;

    // if FIFO not full MAC can write
    assign rx_ready = (count < DEPTH);// generally true only.... coz max latency of parser fsm is 12 clk cycles, depth of dis s 16

    wire write_en = rx_valid && rx_ready;//handshk with mac
    wire read_en  = fifo_valid && fifo_ready;//handshk with hdr buf

    // combinational read to prevent 1 cycle latency
    always @(*) begin
        fifo_valid = (count != 0);// if mac has written anythn
        fifo_data  = data_mem[rd_ptr[ADDR_W-1:0]];//jus trunctin rd_ptr.... basicly data_mem[rd_ptr]
        fifo_last  = last_mem[rd_ptr[ADDR_W-1:0]];//either 0 or 1 based on whether its last or not
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                data_mem[i] <= 8'h00;
                last_mem[i] <= 1'b0;
            end
        end else begin
            case ({write_en, read_en})
                2'b10: begin // write only ie frm mac to dis fifo
                    data_mem[wr_ptr[ADDR_W-1:0]] <= rx_data;// write frm mac
                    last_mem[wr_ptr[ADDR_W-1:0]] <= rx_last;//write 1/0 depending on whether tht byte is last
                    wr_ptr <= wr_ptr + 1;// nxt byte of fifo
                    count  <= count + 1;// no. of entries in buffer incr.
                end

                2'b01: begin // read only
                    rd_ptr <= rd_ptr + 1;// read data tht ws written nxt
                    count  <= count - 1;// no. of entries dec by 1
                end

                2'b11: begin // write and read same cycle
                    data_mem[wr_ptr[ADDR_W-1:0]] <= rx_data;
                    last_mem[wr_ptr[ADDR_W-1:0]] <= rx_last;
                    wr_ptr <= wr_ptr + 1;
                    rd_ptr <= rd_ptr + 1;
                    // count unchanged
                end

                default: ;
            endcase
        end
    end

endmodule
