`timescale 1ns / 1ps

module action_mem #(
    parameter ENTRIES  = 16,
    parameter ACTION_W = 64
)(
    input                       clk,

 
    input                       rd_en,
    input  [$clog2(ENTRIES)-1:0] rd_addr,
    output reg [ACTION_W-1:0]   rd_data,

    input                       wr_en,
    input  [$clog2(ENTRIES)-1:0] wr_addr,
    input  [ACTION_W-1:0]       wr_data
);

   
    reg [ACTION_W-1:0] mem [0:ENTRIES-1];

    
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end

    
    always @(posedge clk) begin
        if (rd_en)
            rd_data <= mem[rd_addr];
    end

endmodule
