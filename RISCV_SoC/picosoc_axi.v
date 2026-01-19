module picosoc_axi #(
    parameter integer MEM_WORDS = 256,
    parameter [31:0] PROGADDR_RESET = 32'h0010_0000,
    parameter [31:0] PROGADDR_IRQ   = 32'h0000_0000
)(
    input clk,
    input resetn,

    // UART
    output ser_tx,
    input  ser_rx,

    // Flash
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
    input  flash_io3_di,

    // External AXI
    output        ext_awvalid,
    input         ext_awready,
    output [31:0] ext_awaddr,

    output        ext_wvalid,
    input         ext_wready,
    output [31:0] ext_wdata,
    output [3:0]  ext_wstrb,

    input         ext_bvalid,
    output        ext_bready,

    output        ext_arvalid,
    input         ext_arready,
    output [31:0] ext_araddr,

    input         ext_rvalid,
    output        ext_rready,
    input  [31:0] ext_rdata
);

    /* ---------------- CPU ---------------- */

    wire awvalid, awready;
    wire [31:0] awaddr;

    wire wvalid, wready;
    wire [31:0] wdata;
    wire [3:0]  wstrb;

    wire bvalid, bready;

    wire arvalid, arready;
    wire [31:0] araddr;

    wire rvalid, rready;
    wire [31:0] rdata;

    wire [31:0] irq = 32'b0;

    picorv32_axi #(
        .PROGADDR_RESET(PROGADDR_RESET),
        .PROGADDR_IRQ(PROGADDR_IRQ)
    ) cpu (
        .clk(clk),
        .resetn(resetn),

        .mem_axi_awvalid(awvalid),
        .mem_axi_awready(awready),
        .mem_axi_awaddr (awaddr),
        .mem_axi_awprot (),

        .mem_axi_wvalid (wvalid),
        .mem_axi_wready (wready),
        .mem_axi_wdata  (wdata),
        .mem_axi_wstrb  (wstrb),

        .mem_axi_bvalid (bvalid),
        .mem_axi_bready (bready),

        .mem_axi_arvalid(arvalid),
        .mem_axi_arready(arready),
        .mem_axi_araddr (araddr),
        .mem_axi_arprot (),

        .mem_axi_rvalid (rvalid),
        .mem_axi_rready (rready),
        .mem_axi_rdata  (rdata),

        .irq(irq)
    );

    /* ---------------- Address decode ---------------- */

    wire sel_ram   = (awaddr < (MEM_WORDS*4)) || (araddr < (MEM_WORDS*4));
    wire sel_spi   = (awaddr >= 32'h0010_0000 && awaddr < 32'h0200_0000) ||
                     (araddr >= 32'h0010_0000 && araddr < 32'h0200_0000);
    wire sel_uart  = (awaddr >= 32'h0200_0004 && awaddr <= 32'h0200_0008) ||
                     (araddr >= 32'h0200_0004 && araddr <= 32'h0200_0008);
    wire sel_ext   = !(sel_ram || sel_spi || sel_uart);

    /* ---------------- RAM ---------------- */

    wire ram_awready, ram_wready, ram_bvalid;
    wire ram_arready, ram_rvalid;
    wire [31:0] ram_rdata;

    picosoc_mem_axi #(
        .WORDS(MEM_WORDS)
    ) ram (
        .clk(clk),
        .resetn(resetn),

        .s_axi_awaddr (awaddr),
        .s_axi_awvalid(awvalid && sel_ram),
        .s_axi_awready(ram_awready),

        .s_axi_wdata (wdata),
        .s_axi_wstrb (wstrb),
        .s_axi_wvalid(wvalid && sel_ram),
        .s_axi_wready(ram_wready),

        .s_axi_bvalid(ram_bvalid),
        .s_axi_bready(bready),

        .s_axi_araddr (araddr),
        .s_axi_arvalid(arvalid && sel_ram),
        .s_axi_arready(ram_arready),

        .s_axi_rdata (ram_rdata),
        .s_axi_rvalid(ram_rvalid),
        .s_axi_rready(rready)
    );

    /* ---------------- SPI Flash ---------------- */

    wire spi_awready, spi_wready, spi_bvalid;
    wire spi_arready, spi_rvalid;
    wire [31:0] spi_rdata;

    spimemio_axi spiflash (
        .clk(clk),
        .resetn(resetn),

        .awaddr (awaddr),
        .awvalid(awvalid && sel_spi),
        .awready(spi_awready),

        .wdata (wdata),
        .wstrb (wstrb),
        .wvalid(wvalid && sel_spi),
        .wready(spi_wready),

        .bvalid(spi_bvalid),
        .bready(bready),

        .araddr (araddr),
        .arvalid(arvalid && sel_spi),
        .arready(spi_arready),

        .rvalid(spi_rvalid),
        .rready(rready),
        .rdata (spi_rdata),

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
        .flash_io3_di(flash_io3_di)
    );

    /* ---------------- UART ---------------- */

    wire uart_awready, uart_wready, uart_bvalid;
    wire uart_arready, uart_rvalid;
    wire [31:0] uart_rdata;

    uart_axi uart (
        .clk(clk),
        .resetn(resetn),

        .awaddr (awaddr),
        .awvalid(awvalid && sel_uart),
        .awready(uart_awready),

        .wdata (wdata),
        .wstrb (wstrb),
        .wvalid(wvalid && sel_uart),
        .wready(uart_wready),

        .bvalid(uart_bvalid),
        .bready(bready),

        .araddr (araddr),
        .arvalid(arvalid && sel_uart),
        .arready(uart_arready),

        .rvalid(uart_rvalid),
        .rready(rready),
        .rdata (uart_rdata),

        .ser_tx(ser_tx),
        .ser_rx(ser_rx)
    );

    /* ---------------- External AXI pass-through ---------------- */

    assign ext_awvalid = awvalid && sel_ext;
    assign ext_awaddr  = awaddr;
    assign ext_wvalid  = wvalid && sel_ext;
    assign ext_wdata   = wdata;
    assign ext_wstrb  = wstrb;
    assign ext_bready = bready;
    assign ext_arvalid = arvalid && sel_ext;
    assign ext_araddr  = araddr;
    assign ext_rready  = rready;

    /* ---------------- Data mux ---------------- */

    assign awready = sel_ram ? ram_awready :
                     sel_spi ? spi_awready :
                     sel_uart ? uart_awready :
                     ext_awready;

    assign wready  = sel_ram ? ram_wready :
                     sel_spi ? spi_wready :
                     sel_uart ? uart_wready :
                     ext_wready;

    assign bvalid  = sel_ram ? ram_bvalid :
                     sel_spi ? spi_bvalid :
                     sel_uart ? uart_bvalid :
                     ext_bvalid;

    assign arready = sel_ram ? ram_arready :
                     sel_spi ? spi_arready :
                     sel_uart ? uart_arready :
                     ext_arready;

    assign rvalid  = sel_ram ? ram_rvalid :
                     sel_spi ? spi_rvalid :
                     sel_uart ? uart_rvalid :
                     ext_rvalid;

    assign rdata   = sel_ram ? ram_rdata :
                     sel_spi ? spi_rdata :
                     sel_uart ? uart_rdata :
                     ext_rdata;

endmodule
