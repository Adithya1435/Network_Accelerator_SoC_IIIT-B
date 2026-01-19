module uart_axi (
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

    output ser_tx,
    input  ser_rx
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

    wire reg_div_sel = p_valid && (p_addr == 32'h0200_0004);
    wire reg_dat_sel = p_valid && (p_addr == 32'h0200_0008);

    wire [31:0] reg_div_do;
    wire [31:0] reg_dat_do;
    wire        reg_dat_wait;

    simpleuart uart (
        .clk(clk),
        .resetn(resetn),

        .ser_tx(ser_tx),
        .ser_rx(ser_rx),

        .reg_div_we(reg_div_sel ? p_wstrb : 4'b0000),
        .reg_div_di(p_wdata),
        .reg_div_do(reg_div_do),

        .reg_dat_we(reg_dat_sel ? p_wstrb[0] : 1'b0),
        .reg_dat_re(reg_dat_sel && !(|p_wstrb)),
        .reg_dat_di(p_wdata),
        .reg_dat_do(reg_dat_do),
        .reg_dat_wait(reg_dat_wait)
    );

    assign p_rdata =
        reg_div_sel ? reg_div_do :
        reg_dat_sel ? reg_dat_do :
        32'h0;

    assign p_ready =
        !reg_dat_sel || !reg_dat_wait;

endmodule
