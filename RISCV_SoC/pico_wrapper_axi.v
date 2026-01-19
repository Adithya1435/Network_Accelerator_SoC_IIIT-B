module pico_wrapper_axi (
    input clk,

    output ser_tx,
    input  ser_rx,

    output flash_csb,
    output flash_clk,
    inout  flash_io0,
    inout  flash_io1,
    inout  flash_io2,
    inout  flash_io3
);

    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    always @(posedge clk)
        reset_cnt <= reset_cnt + !resetn;

    wire flash_io0_oe, flash_io1_oe, flash_io2_oe, flash_io3_oe;
    wire flash_io0_do, flash_io1_do, flash_io2_do, flash_io3_do;

    assign flash_io0 = flash_io0_oe ? flash_io0_do : 1'bz;
    assign flash_io1 = flash_io1_oe ? flash_io1_do : 1'bz;
    assign flash_io2 = flash_io2_oe ? flash_io2_do : 1'bz;
    assign flash_io3 = flash_io3_oe ? flash_io3_do : 1'bz;

    wire ext_awvalid, ext_awready;
    wire [31:0] ext_awaddr;
    wire ext_wvalid, ext_wready;
    wire [31:0] ext_wdata;
    wire [3:0]  ext_wstrb;
    wire ext_bvalid, ext_bready;
    wire ext_arvalid, ext_arready;
    wire [31:0] ext_araddr;
    wire ext_rvalid, ext_rready;
    wire [31:0] ext_rdata;

    picosoc_axi soc (
        .clk(clk),
        .resetn(resetn),

        .ser_tx(ser_tx),
        .ser_rx(ser_rx),

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

        .flash_io0_di(flash_io0),
        .flash_io1_di(flash_io1),
        .flash_io2_di(flash_io2),
        .flash_io3_di(flash_io3),

        .ext_awvalid(ext_awvalid),
        .ext_awready(ext_awready),
        .ext_awaddr(ext_awaddr),

        .ext_wvalid(ext_wvalid),
        .ext_wready(ext_wready),
        .ext_wdata(ext_wdata),
        .ext_wstrb(ext_wstrb),

        .ext_bvalid(ext_bvalid),
        .ext_bready(ext_bready),

        .ext_arvalid(ext_arvalid),
        .ext_arready(ext_arready),
        .ext_araddr(ext_araddr),

        .ext_rvalid(ext_rvalid),
        .ext_rready(ext_rready),
        .ext_rdata(ext_rdata)
    );

    assign ext_awready = 1'b0;
    assign ext_wready  = 1'b0;
    assign ext_bvalid  = 1'b0;
    assign ext_arready = 1'b0;
    assign ext_rvalid  = 1'b0;
    assign ext_rdata   = 32'b0;

endmodule
