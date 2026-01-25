`timescale 1ns / 1ps

module tcam_mmio #(
    parameter KEY_W   = 128,
    parameter ENTRIES = 16,
    parameter IDX_W = $clog2(ENTRIES),
    parameter BASE_ADDR = 32'h0300_0000
)(
    input              clk,
    input              resetn,

    input              mem_valid,
    output             mem_ready,
    input      [31:0]  mem_addr,
    input      [31:0]  mem_wdata,
    input      [3:0]   mem_wstrb,
    output reg [31:0]  mem_rdata,

    output reg [IDX_W-1:0] tcam_wr_addr,
    output reg             tcam_wr_is_mask,
    output reg [KEY_W-1:0] tcam_wr_data,
    output reg             tcam_wr_en

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
            tcam_wr_addr       <= 0;
            tcam_wr_is_mask    <= 0;
            tcam_wr_data       <= 0;
            tcam_wr_en         <= 0;
        end else begin
            tcam_wr_en         <= 0;

            if (write) begin
                case (offset)

                    8'h00: tcam_wr_addr          <= mem_wdata[IDX_W-1:0];
                    8'h04: tcam_wr_is_mask       <= mem_wdata[0];

                    8'h08: tcam_wr_data[31:0]    <= mem_wdata;
                    8'h0C: tcam_wr_data[63:32]   <= mem_wdata;
                    8'h10: tcam_wr_data[95:64]   <= mem_wdata;
                    8'h14: tcam_wr_data[127:96]  <= mem_wdata;

                    8'h18: tcam_wr_en            <= mem_wdata[0];
                endcase
            end
        end
    end

    always @(*) begin
        mem_rdata = 32'h0;

        if (sel && read) begin
            case (offset)
                8'h00: mem_rdata <= tcam_wr_addr;
                8'h04: mem_rdata <= tcam_wr_is_mask;

                8'h08: mem_rdata <= tcam_wr_data[31:0];
                8'h0C: mem_rdata <= tcam_wr_data[63:32];
                8'h10: mem_rdata <= tcam_wr_data[95:64];
                8'h14: mem_rdata <= tcam_wr_data[127:96];

                8'h18: mem_rdata <= tcam_wr_en;
            endcase
        end
    end

endmodule
