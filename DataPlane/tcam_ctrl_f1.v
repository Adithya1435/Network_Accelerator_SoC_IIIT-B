`timescale 1ns / 1ps

module tcam_ctrl #(
    parameter KEY_W   = 128,
    parameter ENTRIES = 16
)(
    input                       clk,
    input                       rst_n,

    
    input  [KEY_W-1:0]          key,
    input                       key_valid,

   
    input                       wr_en,
    input                       wr_is_mask,   // 0 = value, 1 = mask
    input  [$clog2(ENTRIES)-1:0] wr_addr,
    input  [KEY_W-1:0]          wr_data,

    
    output reg                  hit,
    output reg [$clog2(ENTRIES)-1:0] hit_index
);

    localparam IDX_W = $clog2(ENTRIES);

    
    reg [KEY_W-1:0] tcam_value [0:ENTRIES-1];
    reg [KEY_W-1:0] tcam_mask  [0:ENTRIES-1];

  
    wire [ENTRIES-1:0] match;

    genvar i;
    generate
        for (i = 0; i < ENTRIES; i = i + 1) begin : TCAM_COMPARE
            assign match[i] =
                ((key & ~tcam_mask[i]) ==
                 (tcam_value[i] & ~tcam_mask[i]));
        end
    endgenerate


    always @(posedge clk or negedge rst_n) begin//ctrl plane writes
        if (!rst_n) begin

        end else if (wr_en) begin
            if (wr_is_mask)
                tcam_mask[wr_addr]  <= wr_data;
            else
                tcam_value[wr_addr] <= wr_data;
        end
    end

  
    integer j;
    always @(*) begin//low index proirity encoder
        hit       = 1'b0;
        hit_index = {IDX_W{1'b0}};

        if (key_valid) begin
            for (j = 0; j < ENTRIES; j = j + 1) begin
                if (match[j] && !hit) begin
                    hit       = 1'b1;
                    hit_index = j[IDX_W-1:0];
                end
            end
        end
    end

endmodule
