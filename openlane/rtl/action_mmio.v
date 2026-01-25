`timescale 1ns / 1ps

module action_mmio #(
    parameter ENTRIES    = 16,
    parameter ACTION_W   = 64,
    parameter IDX_W      = $clog2(ENTRIES),
    parameter BASE_ADDR  = 32'h0301_0000
)(
    input              clk,
    input              resetn,

    input              mem_valid,
    output             mem_ready,
    input      [31:0]  mem_addr,
    input      [31:0]  mem_wdata,
    input      [3:0]   mem_wstrb,
    output reg [31:0]  mem_rdata,


    output reg                  action_wr_en,
    output reg [IDX_W-1:0]      action_wr_addr,
    output reg [ACTION_W-1:0]   action_wr_data,

    output reg                  action_wr_default,
    output reg [ACTION_W-1:0]   action_default_data
);

    wire sel = mem_valid &&
               (mem_addr >= BASE_ADDR) &&
               (mem_addr < BASE_ADDR + 32'h100);

    assign mem_ready = sel;

    wire write = sel && |mem_wstrb;
    wire read  = sel && ~(|mem_wstrb);

    wire [7:0] offset = mem_addr[7:0];



    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            action_wr_en        <= 1'b0;
            action_wr_default   <= 1'b0;
            action_wr_addr      <= {IDX_W{1'b0}};
            action_wr_data      <= {ACTION_W{1'b0}};
            action_default_data <= {ACTION_W{1'b0}};
        end else begin
            action_wr_en      <= 1'b0;
            action_wr_default <= 1'b0;

            if (write && mem_wstrb == 4'b1111) begin
                case (offset)

                    8'h00: action_wr_addr           <= mem_wdata[IDX_W-1:0];

                    8'h04: action_wr_data[31:0]     <= mem_wdata;
                    8'h08: action_wr_data[63:32]    <= mem_wdata;

                    8'h0C: action_wr_en             <= mem_wdata[0];


                    8'h10: action_default_data[31:0]  <= mem_wdata;
                    8'h14: action_default_data[63:32] <= mem_wdata;

                    8'h18: action_wr_default           <= mem_wdata[0];
                endcase
            end
        end
    end


    always @(*) begin
        mem_rdata = 32'h0;

        if (sel && read) begin
            case (offset)
                8'h00: mem_rdata = action_wr_addr;
                8'h04: mem_rdata = action_wr_data[31:0];
                8'h08: mem_rdata = action_wr_data[63:32];
                8'h0C: mem_rdata = action_wr_en;

                8'h10: mem_rdata = action_default_data[31:0];
                8'h14: mem_rdata = action_default_data[63:32];
                8'h18: mem_rdata = action_wr_default;
            endcase
        end
    end

endmodule
