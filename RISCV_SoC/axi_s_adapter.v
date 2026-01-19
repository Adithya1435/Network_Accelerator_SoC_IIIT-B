module axi_s_adapter (
    input  wire        clk,
    input  wire        resetn,

    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    input  wire [31:0] s_axi_awaddr,

    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,

    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    input  wire [31:0] s_axi_araddr,

    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    output reg  [31:0] s_axi_rdata,

    // Simple peripheral interface
    output reg         periph_valid,
    input  wire        periph_ready,
    output reg  [31:0] periph_addr,
    output reg  [31:0] periph_wdata,
    output reg  [ 3:0] periph_wstrb,
    input  wire [31:0] periph_rdata
);

    localparam IDLE  = 2'd0;
    localparam WRITE = 2'd1;
    localparam READ  = 2'd2;

    reg [1:0] state;


    always @(posedge clk) begin
        if (!resetn) begin
            state           <= IDLE;

            s_axi_awready   <= 0;
            s_axi_wready    <= 0;
            s_axi_bvalid    <= 0;
            s_axi_arready   <= 0;
            s_axi_rvalid    <= 0;

            periph_valid    <= 0;
            periph_wstrb    <= 0;
        end else begin
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_arready <= 0;

            case (state)
            IDLE: begin
                periph_valid <= 0;

                if (s_axi_awvalid && s_axi_wvalid) begin
                    s_axi_awready <= 1;
                    s_axi_wready  <= 1;

                    periph_valid  <= 1;
                    periph_addr   <= s_axi_awaddr;
                    periph_wdata  <= s_axi_wdata;
                    periph_wstrb  <= s_axi_wstrb;

                    state <= WRITE;
                end

                else if (s_axi_arvalid) begin
                    s_axi_arready <= 1;

                    periph_valid  <= 1;
                    periph_addr   <= s_axi_araddr;
                    periph_wstrb  <= 4'b0000;

                    state <= READ;
                end
            end

            WRITE: begin
                if (periph_ready) begin
                    periph_valid <= 0;
                    s_axi_bvalid <= 1;

                    if (s_axi_bready) begin
                        s_axi_bvalid <= 0;
                        state <= IDLE;
                    end
                end
            end

            READ: begin
                if (periph_ready) begin
                    periph_valid <= 0;
                    s_axi_rvalid <= 1;
                    s_axi_rdata  <= periph_rdata;

                    if (s_axi_rready) begin
                        s_axi_rvalid <= 0;
                        state <= IDLE;
                    end
                end
            end

            endcase
        end
    end
endmodule
