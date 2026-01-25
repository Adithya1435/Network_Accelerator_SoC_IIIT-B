`timescale 1ns / 1ps
module action_pipe #(
    parameter ENTRIES  = 16,
    parameter ACTION_W = 64
)(
    input                       clk,
    input                       rst_n,

    //frm tcam
    input                       tcam_valid,
    input                       hit,
    input  [$clog2(ENTRIES)-1:0] hit_index,

    // To forwarding / drop logic
    output reg                  action_valid,
    output reg [ACTION_W-1:0]   action,

    // ctrl plane writes
    input                       wr_en,
    input  [$clog2(ENTRIES)-1:0] wr_addr,
    input  [ACTION_W-1:0]       wr_data,

    input                       wr_default,
    input  [ACTION_W-1:0]       default_data
);

    reg [ACTION_W-1:0] mem [0:ENTRIES-1];
    reg [ACTION_W-1:0] default_action;

    // ctrl plane
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
        if (wr_default)
            default_action <= default_data;
    end

    // dataplane
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            action_valid <= 1'b0;
        end else begin
            action_valid <= tcam_valid;

            if (tcam_valid) begin
                if (hit)
                    action <= mem[hit_index];
                else
                    action <= default_action;
            end
        end
    end
endmodule
