`timescale 1ns / 1ps

module header_buffer
#(
    parameter HEADER_BYTES = 192,
    parameter PTR_W = 8
)
(
    input            clk,
    input            rst_n,

    input            rx_valid,
    input  [7:0]     rx_data,
    input            rx_last,

    output           rx_ready,

    output reg [8*HEADER_BYTES-1:0] header_flat,
    output reg [PTR_W:0]            header_len,
    output reg                      header_done
);

    reg [PTR_W:0] wr_ptr;
    reg           in_packet;
    integer       i;

    assign rx_ready = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr      <= 0;
            header_len  <= 0;
            header_done <= 0;
            in_packet   <= 0;
            for (i = 0; i < HEADER_BYTES; i = i + 1)
                header_flat[i*8 +: 8] <= 8'h00;
        end else begin
            header_done <= 1'b0;

            if (rx_valid) begin
                if (!in_packet) begin
                    
                    in_packet  <= 1'b1;
                    wr_ptr     <= 0;
                    header_len <= 0;

                   
                    header_flat[0*8 +: 8] <= rx_data;
                    wr_ptr <= 1;
                    header_len <= 1;
                end else begin
                    
                    if (wr_ptr < HEADER_BYTES) begin
                        header_flat[wr_ptr*8 +: 8] <= rx_data;
                        wr_ptr <= wr_ptr + 1;
                    end
                    header_len <= header_len + 1;
                end

                if (rx_last) begin
                    in_packet   <= 1'b0;
                    header_done <= 1'b1;
                end
            end
        end
    end

endmodule




