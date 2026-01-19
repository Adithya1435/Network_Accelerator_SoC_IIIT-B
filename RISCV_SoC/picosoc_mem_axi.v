module picosoc_mem_axi #(
    parameter integer WORDS = 256,
    parameter integer ADDR_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   resetn,

    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    input  wire [31:0]            s_axi_wdata,
    input  wire [3:0]             s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    output reg  [31:0]            s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);


    reg [31:0] mem [0:WORDS-1];

    wire [21:0] aw_word = s_axi_awaddr[23:2];
    wire [21:0] ar_word = s_axi_araddr[23:2];

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 2'b00;
        end else begin

            s_axi_awready <= 0;
            s_axi_wready  <= 0;

            if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_awready <= 1;
                s_axi_wready  <= 1;

                if (aw_word < WORDS) begin
                    if (s_axi_wstrb[0]) mem[aw_word][ 7: 0] <= s_axi_wdata[ 7: 0];
                    if (s_axi_wstrb[1]) mem[aw_word][15: 8] <= s_axi_wdata[15: 8];
                    if (s_axi_wstrb[2]) mem[aw_word][23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) mem[aw_word][31:24] <= s_axi_wdata[31:24];
                    s_axi_bresp <= 2'b00;
                end else begin
                    s_axi_bresp <= 2'b10;
                end

                s_axi_bvalid <= 1;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 0;
            end
        end
    end


    reg [21:0] ar_word_d;
    reg        read_pending;

    always @(posedge clk) begin
        if (!resetn) begin
            s_axi_arready  <= 0;
            s_axi_rvalid   <= 0;
            s_axi_rdata    <= 0;
            s_axi_rresp    <= 2'b00;
            read_pending   <= 0;
        end else begin
            s_axi_arready <= 0;

            if (s_axi_arvalid && !read_pending && !s_axi_rvalid) begin
                s_axi_arready <= 1;
                ar_word_d     <= ar_word;
                read_pending  <= 1;
            end

            if (read_pending) begin
                if (ar_word_d < WORDS) begin
                    s_axi_rdata <= mem[ar_word_d];
                    s_axi_rresp <= 2'b00;
                end else begin
                    s_axi_rdata <= 32'h0;
                    s_axi_rresp <= 2'b10;
                end
                s_axi_rvalid  <= 1;
                read_pending  <= 0;
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 0;
            end
        end
    end

endmodule
