`timescale 1ns / 1ps

module tcam_ctrl_pipe #(
    parameter KEY_W   = 128,
    parameter ENTRIES = 16
)(
    input                       clk,
    input                       rst_n,

    
    input  [KEY_W-1:0]          key,// frm key builder
    input                       key_valid,// frm pipeline reg

    // frm control plane
    input                       wr_en,//enable write signal by ctrl plane
    input                       wr_is_mask,   // 0 = value, 1 = mask
    input  [$clog2(ENTRIES)-1:0] wr_addr,//which entry to write
    input  [KEY_W-1:0]          wr_data,//by processor

    
    output reg                  hit,// 1 or 0 based on whether key has matched any rule
    output reg [$clog2(ENTRIES)-1:0] hit_index//address which has hit 
);

    localparam IDX_W = $clog2(ENTRIES);// 4

    
    reg [KEY_W-1:0] tcam_value [0:ENTRIES-1];//each tcam value is 128 bits,a nd there r 16 such tcam values
    reg [KEY_W-1:0] tcam_mask  [0:ENTRIES-1];//similarly for mask

  
    wire [ENTRIES-1:0] match;// each of 16 bits is 1 or 0 bsed on whether masked key and value hv matched

    always @(posedge clk or negedge rst_n) begin//ctrl plane writes
        if (!rst_n) begin
            for (k = 0; k < ENTRIES; k = k + 1) begin
                tcam_value[k] <= {KEY_W{1'b0}};
                tcam_mask[k] <= {KEY_W{1'b1}};
            end
        end else if (wr_en) begin
            if (wr_is_mask)// its writing mask
                tcam_mask[wr_addr]  <= wr_data;
            else
                tcam_value[wr_addr] <= wr_data;// its writing value
        end
    end

    
    
    genvar i;
    generate
        for (i = 0; i < ENTRIES; i = i + 1) begin : TCAM_COMPARE// matching
            assign match[i] =
                ((key & ~tcam_mask[i]) ==
                 (tcam_value[i] & ~tcam_mask[i]));// is mask =1, thn ignore (just equates 0 to 0 for tht bit)                             
        end
    endgenerate

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
