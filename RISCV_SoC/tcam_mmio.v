`timescale 1ns / 1ps

module tcam_mmio #(
    parameter KEY_W   = 128,
    parameter ENTRIES = 16,
    parameter BASE_ADDR = 32'h0300_0000
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

    localparam IDX_W = $clog2(ENTRIES);

    reg [KEY_W-1:0] key_reg;
    reg             key_valid_reg;

    reg [IDX_W-1:0] wr_addr;
    reg             wr_is_mask;
    reg [KEY_W-1:0] wr_data;
    reg             wr_en;

    wire hit;
    wire [IDX_W-1:0] hit_index;

    reg hit_reg;
    reg [IDX_W-1:0] hit_index_reg;

    wire sel = mem_valid &&
               (mem_addr >= BASE_ADDR) &&
               (mem_addr < BASE_ADDR + 32'h100);

    assign mem_ready = sel;

    wire write = sel && |mem_wstrb;
    wire read  = sel && ~(|mem_wstrb);

    wire [7:0] offset = mem_addr[7:0];


    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            key_reg       <= 0;
            key_valid_reg <= 0;
            wr_addr       <= 0;
            wr_is_mask    <= 0;
            wr_data       <= 0;
            wr_en         <= 0;
        end else begin
            wr_en         <= 0;
            key_valid_reg <= 0;

            if (write) begin
                case (offset)
                    8'h00: key_reg[31:0]    <= mem_wdata;
                    8'h04: key_reg[63:32]   <= mem_wdata;
                    8'h08: key_reg[95:64]   <= mem_wdata;
                    8'h0C: key_reg[127:96]  <= mem_wdata;

                    8'h10: key_valid_reg    <= mem_wdata[0];

                    8'h20: wr_addr          <= mem_wdata[IDX_W-1:0];
                    8'h24: wr_is_mask       <= mem_wdata[0];

                    8'h28: wr_data[31:0]    <= mem_wdata;
                    8'h2C: wr_data[63:32]   <= mem_wdata;
                    8'h30: wr_data[95:64]   <= mem_wdata;
                    8'h34: wr_data[127:96]  <= mem_wdata;

                    8'h38: wr_en            <= mem_wdata[0];
                endcase
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            hit_reg       <= 1'b0;
            hit_index_reg <= {IDX_W{1'b0}};
        end else begin
            if (key_valid_reg) begin
                hit_reg       <= hit;
                hit_index_reg <= hit_index;
            end
        end
    end

    always @(*) begin
        mem_rdata = 32'h0;
        if (read) begin
            case (offset)
                8'h14: mem_rdata = {31'b0, hit_reg};
                8'h18: mem_rdata = hit_index_reg;
                default: mem_rdata = 32'h0;
            endcase
        end
    end

    tcam_ctrl_pipe #(
        .KEY_W(KEY_W),
        .ENTRIES(ENTRIES)
    ) tcam (
        .clk(clk),
        .rst_n(resetn),

        .key(key_reg),
        .key_valid(key_valid_reg),

        .wr_en(wr_en),
        .wr_is_mask(wr_is_mask),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .hit(hit),
        .hit_index(hit_index)
    );

endmodule
