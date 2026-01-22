`timescale 1ns / 1ps

module action_mmio #(
    parameter ACTION_W  = 64,
    parameter BASE_ADDR = 32'h0301_0000
)(
    input              clk,
    input              resetn,

    input              mem_valid,
    output             mem_ready,
    input      [31:0]  mem_addr,
    input      [31:0]  mem_wdata,
    input      [3:0]   mem_wstrb,
    output reg [31:0]  mem_rdata
);

    reg [ACTION_W-1:0] action_reg;
    reg                action_valid_reg;
    reg                pkt_start_reg;

    reg                allow_drain_reg;
    reg [ACTION_W-1:0] action_latched_reg;

    wire               allow_drain;
    wire [ACTION_W-1:0] action_latched;
    wire               pkt_start_latched;

    wire sel = mem_valid &&
               (mem_addr >= BASE_ADDR) &&
               (mem_addr < BASE_ADDR + 32'h100);

    assign mem_ready = sel;

    wire write = sel && |mem_wstrb;
    wire read  = sel && ~(|mem_wstrb);

    wire [7:0] offset = mem_addr[7:0];

    //write
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            action_reg        <= 0;
            action_valid_reg  <= 0;
            pkt_start_reg     <= 0;
        end else begin
            action_valid_reg <= 0;
            pkt_start_reg    <= 0;

            if (write) begin
                case (offset)
                    8'h00: action_reg[31:0]  <= mem_wdata;
                    8'h04: action_reg[63:32] <= mem_wdata;

                    8'h08: action_valid_reg  <= mem_wdata[0];
                    8'h0C: pkt_start_reg     <= mem_wdata[0];
                endcase
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            allow_drain_reg    <= 1'b0;
            action_latched_reg <= 0;
        end else begin
            if (allow_drain) begin
                allow_drain_reg    <= 1'b1;
                action_latched_reg <= action_latched;
            end
        end
    end

    //read
    always @(*) begin
        mem_rdata = 32'h0;
        if (read) begin
            case (offset)
                8'h10: mem_rdata = {31'b0, allow_drain_reg};
                8'h14: mem_rdata = action_latched_reg[31:0];
                8'h18: mem_rdata = action_latched_reg[63:32];
                default: mem_rdata = 32'h0;
            endcase
        end
    end

    action_drain_ctrl_upper #(
        .ACTION_W(ACTION_W)
    ) action_ctrl (
        .clk(clk),
        .rst_n(resetn),

        .action_valid(action_valid_reg),
        .action_in(action_reg),

        .pkt_start_in(pkt_start_reg),

        .allow_drain(allow_drain),
        .action_latched(action_latched),
        .pkt_start_latched(pkt_start_latched)
    );

endmodule
