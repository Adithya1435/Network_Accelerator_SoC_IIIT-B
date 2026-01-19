module spimemio_axi (
    input clk,
    input resetn,

    input         awvalid,
    output        awready,
    input  [31:0] awaddr,

    input         wvalid,
    output        wready,
    input  [31:0] wdata,
    input  [3:0]  wstrb,

    output        bvalid,
    input         bready,

    input         arvalid,
    output        arready,
    input  [31:0] araddr,

    output        rvalid,
    input         rready,
    output [31:0] rdata,

    output flash_csb,
    output flash_clk,

    output flash_io0_oe,
    output flash_io1_oe,
    output flash_io2_oe,
    output flash_io3_oe,

    output flash_io0_do,
    output flash_io1_do,
    output flash_io2_do,
    output flash_io3_do,

    input  flash_io0_di,
    input  flash_io1_di,
    input  flash_io2_di,
    input  flash_io3_di
);

    wire        p_valid;
    wire        p_ready;
    wire [31:0] p_addr;
    wire [31:0] p_wdata;
    wire [3:0]  p_wstrb;
    wire [31:0] p_rdata;

    axi_s_adapter axi2p (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_awaddr (awaddr),

        .s_axi_wvalid (wvalid),
        .s_axi_wready (wready),
        .s_axi_wdata  (wdata),
        .s_axi_wstrb  (wstrb),

        .s_axi_bvalid (bvalid),
        .s_axi_bready (bready),

        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_araddr (araddr),

        .s_axi_rvalid (rvalid),
        .s_axi_rready (rready),
        .s_axi_rdata  (rdata),

        .periph_valid (p_valid),
        .periph_ready (p_ready),
        .periph_addr  (p_addr),
        .periph_wdata (p_wdata),
        .periph_wstrb (p_wstrb),
        .periph_rdata (p_rdata)
    );

    wire cfg_sel = (p_addr == 32'h0200_0000);

    spimemio spimem (
        .clk(clk),
        .resetn(resetn),

        .valid(p_valid && !cfg_sel),
        .ready(p_ready),
        .addr(p_addr[23:0]),
        .rdata(p_rdata),

        .flash_csb(flash_csb),
        .flash_clk(flash_clk),

        .flash_io0_oe(flash_io0_oe),
        .flash_io1_oe(flash_io1_oe),
        .flash_io2_oe(flash_io2_oe),
        .flash_io3_oe(flash_io3_oe),

        .flash_io0_do(flash_io0_do),
        .flash_io1_do(flash_io1_do),
        .flash_io2_do(flash_io2_do),
        .flash_io3_do(flash_io3_do),

        .flash_io0_di(flash_io0_di),
        .flash_io1_di(flash_io1_di),
        .flash_io2_di(flash_io2_di),
        .flash_io3_di(flash_io3_di),

        .cfgreg_we(cfg_sel ? p_wstrb : 4'b0000),
        .cfgreg_di(p_wdata),
        .cfgreg_do(p_rdata)
    );

endmodule
