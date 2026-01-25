module network_top(

    `ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
	`endif

	input clk,
	input resetn,

	//into the bottom fifo (i/p)
    input  wire        rx_valid,
    input  wire [7:0]  rx_data,
    input  wire        rx_last,
    output wire        rx_ready,

    //to the output (egress mac)
    output wire        tx_valid,
    output wire [7:0]  tx_data,
    output wire        tx_last,
    input  wire        tx_ready,

    //uart
	output ser_tx,
	input ser_rx,


    //spi flash
	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	inout  flash_io2,
	inout  flash_io3

);

    localparam KEY_W   = 128;
    localparam ENTRIES = 16;
    localparam IDX_W = $clog2(ENTRIES);
    localparam ACTION_W = 64;

    //tcam
    wire [IDX_W-1:0] tcam_wr_addr;
    wire             tcam_wr_is_mask;
    wire [KEY_W-1:0] tcam_wr_data;
    wire             tcam_wr_en;

    //action
	wire                  action_wr_en;
    wire [IDX_W-1:0]      action_wr_addr;
    wire [ACTION_W-1:0]   action_wr_data;
    wire                  action_wr_default;
    wire [ACTION_W-1:0]   action_default_data;


    dataplane_top dataplane(
        .clk                     (clk),
        .rst_n                   (resetn),
        .rx_valid                (rx_valid),
        .rx_data                 (rx_data),
        .rx_last                 (rx_last),
        .rx_ready                (rx_ready),
        .tx_valid                (tx_valid),
        .tx_data                 (tx_data),
        .tx_last                 (tx_last),
        .tx_ready                (tx_ready),
        .cfg_tcam_wr_en          (tcam_wr_en),
        .cfg_tcam_wr_is_mask     (tcam_wr_is_mask),
        .cfg_tcam_wr_addr        (tcam_wr_addr),
        .cfg_tcam_wr_data        (tcam_wr_data),
        .cfg_action_wr_en        (action_wr_en),
        .cfg_action_wr_addr      (action_wr_addr),
        .cfg_action_wr_data      (action_wr_data),
        .cfg_action_wr_default   (action_wr_default),
        .cfg_action_default_data (action_default_data)
    );

    //ctrlplane
    pico_wrapper soc_wrapper (

        `ifdef USE_POWER_PINS
		.vccd1               (vccd1),
		.vssd1               (vssd1),
		`endif

		.clk                 (clk),
		.resetn              (resetn),
		.ser_rx              (ser_rx),
		.ser_tx              (ser_tx),

		.tcam_wr_addr        (tcam_wr_addr),
		.tcam_wr_is_mask     (tcam_wr_is_mask),
		.tcam_wr_data        (tcam_wr_data),
		.tcam_wr_en          (tcam_wr_en),

		.action_wr_en        (action_wr_en),
		.action_wr_addr      (action_wr_addr),
		.action_wr_data      (action_wr_data),
		.action_wr_default   (action_wr_default),
		.action_default_data (action_default_data),

		.flash_csb           (flash_csb),
		.flash_clk           (flash_clk),
		.flash_io0           (flash_io0),
		.flash_io1           (flash_io1),
		.flash_io2           (flash_io2),
		.flash_io3           (flash_io3)
	);

endmodule
