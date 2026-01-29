module pico_wrapper #(
    parameter KEY_W   = 128,
    parameter ENTRIES = 16,
    parameter IDX_W = $clog2(ENTRIES),
    parameter ACTION_W = 64
)(

	`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
	`endif

	input clk,
	input resetn,

	output ser_tx,
	input ser_rx,

	//tcam
	output reg [IDX_W-1:0] tcam_wr_addr,
    output reg             tcam_wr_is_mask,
    output reg [KEY_W-1:0] tcam_wr_data,
    output reg             tcam_wr_en,

    //action
	output reg                  action_wr_en,
    output reg [IDX_W-1:0]      action_wr_addr,
    output reg [ACTION_W-1:0]   action_wr_data,
    output reg                  action_wr_default,
    output reg [ACTION_W-1:0]   action_default_data,

	output flash_csb,
	output flash_clk,
	inout  flash_io0,
	inout  flash_io1,
	inout  flash_io2,
	inout  flash_io3
);
	parameter integer MEM_WORDS = 256;

	wire flash_io0_oe, flash_io0_do, flash_io0_di;
	wire flash_io1_oe, flash_io1_do, flash_io1_di;
	wire flash_io2_oe, flash_io2_do, flash_io2_di;
	wire flash_io3_oe, flash_io3_do, flash_io3_di;


	assign flash_io0 = flash_io0_oe ? flash_io0_do : 1'bz;
	assign flash_io1 = flash_io1_oe ? flash_io1_do : 1'bz;
	assign flash_io2 = flash_io2_oe ? flash_io2_do : 1'bz;
	assign flash_io3 = flash_io3_oe ? flash_io3_do : 1'bz;

	assign flash_io0_di = flash_io0_oe ? 1'b0 : flash_io0;
	assign flash_io1_di = flash_io1_oe ? 1'b0 : flash_io1;
	assign flash_io2_di = flash_io2_oe ? 1'b0 : flash_io2;
	assign flash_io3_di = flash_io3_oe ? 1'b0 : flash_io3;

	wire        iomem_valid;
	reg         iomem_ready;
	wire [3:0]  iomem_wstrb;
	wire [31:0] iomem_addr;
	wire [31:0] iomem_wdata;
	reg  [31:0] iomem_rdata;

	reg [31:0] gpio;

	always @(posedge clk) begin
		if (!resetn) begin
			gpio <= 0;
		end else begin
			iomem_ready <= 0;
			if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h 03) begin
				iomem_ready <= 1;
				iomem_rdata <= gpio;
				if (iomem_wstrb[0]) gpio[ 7: 0] <= iomem_wdata[ 7: 0];
				if (iomem_wstrb[1]) gpio[15: 8] <= iomem_wdata[15: 8];
				if (iomem_wstrb[2]) gpio[23:16] <= iomem_wdata[23:16];
				if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24];
			end
		end
	end

	picosoc #(
		.BARREL_SHIFTER(0),
		.ENABLE_MUL(0),
		.ENABLE_DIV(0),
		.ENABLE_FAST_MUL(1),
		.MEM_WORDS(MEM_WORDS)
	) soc (

		`ifdef USE_POWER_PINS
		.vccd1               (vccd1),
		.vssd1               (vssd1),
		`endif

		.clk                 (clk),
		.resetn              (resetn),

		.ser_tx              (ser_tx),
		.ser_rx              (ser_rx),

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

		.flash_io0_oe        (flash_io0_oe),
		.flash_io1_oe        (flash_io1_oe),
		.flash_io2_oe        (flash_io2_oe),
		.flash_io3_oe        (flash_io3_oe),

		.flash_io0_do        (flash_io0_do),
		.flash_io1_do        (flash_io1_do),
		.flash_io2_do        (flash_io2_do),
		.flash_io3_do        (flash_io3_do),

		.flash_io0_di        (flash_io0_di),
		.flash_io1_di        (flash_io1_di),
		.flash_io2_di        (flash_io2_di),
		.flash_io3_di        (flash_io3_di),

		.irq_5               (1'b0),
		.irq_6               (1'b0),
		.irq_7               (1'b0),

		.iomem_valid         (iomem_valid),
		.iomem_ready         (iomem_ready),
		.iomem_wstrb         (iomem_wstrb),
		.iomem_addr          (iomem_addr),
		.iomem_wdata         (iomem_wdata),
		.iomem_rdata         (iomem_rdata)
	);
endmodule
