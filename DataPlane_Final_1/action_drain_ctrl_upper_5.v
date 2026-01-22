`timescale 1ns / 1ps
module action_drain_ctrl_upper #(
    parameter ACTION_W = 64
) (
    input  wire              clk,
    input  wire              rst_n,

    //frm action
    input  wire              action_valid,
    input  wire [ACTION_W-1:0] action_in,

    // frm parser
    input  wire              pkt_start_in,

    // to the fifo b4 dis
    output reg               allow_drain,      // 1-cycle pulse
    output reg [ACTION_W-1:0] action_latched,
    output reg               pkt_start_latched
);

always @(posedge clk) begin
    if (!rst_n) begin
        allow_drain       <= 1'b0;
        action_latched    <= {ACTION_W{1'b0}};
        pkt_start_latched <= 1'b0;
    end else begin
        
        allow_drain       <= 1'b0;
        pkt_start_latched <= 1'b0;

        //latch action nd fire 1 cycl drain pulse
        if (action_valid) begin
            action_latched <= action_in;
            allow_drain    <= 1'b1;  
        end

        // latch the sop
        if (pkt_start_in) begin
            pkt_start_latched <= 1'b1; //1 cycle only
        end
    end
end

endmodule


