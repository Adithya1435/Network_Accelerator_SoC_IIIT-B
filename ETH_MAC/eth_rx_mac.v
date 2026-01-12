`timescale 1ns / 1ps

module eth_rx_mac (
    input  wire        rx_clk,
    input  wire        rst_n,


    input  wire [3:0]  rxd,
    input  wire        rx_dv,
    input  wire        rx_er,


    output reg  [7:0]  rx_data, //rx_byte,
    output reg         rx_valid, //rx_byte_valid,
    output reg         rx_last, //rx_frame_end,

    output reg         rx_frame_start, //*** this is not needed for the next header_buffer or FIFO stage as it reads only they rx_valid signal to see when the byte can be accepted
    
    output reg         rx_frame_error //this is important for the real implementation, hasnt been used
);


    reg [3:0] nibble_lo;
    reg       nibble_phase;
    reg [7:0] byte_data;
    reg       byte_valid;

    //reg [10:0] byte_count; // counts 0 to 2047, enough for 1518 max, this is the new addition that makes sure that the packet is within the limits



    always @(posedge rx_clk) begin
        if (!rst_n) begin   
            nibble_phase <= 0;
            byte_valid   <= 0;
        end else begin 
            byte_valid <= 0;
            if (!rx_dv) begin
                nibble_phase <= 0;
            end else if (!nibble_phase) begin
                nibble_lo <= rxd;
                nibble_phase <= 1;
            end else begin
                byte_data <= {rxd, nibble_lo};
                byte_valid <= 1;
                nibble_phase <= 0;
            end
        end
    end


    localparam IDLE=2'd0, PREAMBLE=2'd1, RECEIVE=2'd2, DROP=2'd3;
    reg [1:0] state;
    reg [2:0] pre_cnt;
    reg       first_data_byte;

    always @(posedge rx_clk) begin
        if (!rst_n) begin
            state            <= IDLE;
            pre_cnt          <= 0;
            rx_valid    <= 0;
            rx_frame_start   <= 0;
            rx_last     <= 0;
            rx_frame_error   <= 0;
            first_data_byte  <= 0;
        end else begin
            rx_valid  <= 0;
            rx_frame_start <= 0;
            rx_last   <= 0;
            rx_frame_error <= 0;

 
            if (!rx_dv && state == RECEIVE) begin
                rx_last <= 1;
                state <= IDLE;
            end

            if (byte_valid) begin
                case (state)
                    IDLE: begin
                        if (byte_data == 8'h55) begin
                            pre_cnt <= 1;
                            state <= PREAMBLE;
                        end
                    end

                    PREAMBLE: begin
                        if (byte_data == 8'h55)
                            pre_cnt <= pre_cnt + 1;
                        else if (byte_data == 8'hD5 && pre_cnt >= 6) begin
                            state <= RECEIVE;
                            first_data_byte <= 1;
                        end else
                            state <= DROP;
                    end

                    RECEIVE: begin
                        rx_data <= byte_data;
                        rx_valid <= 1;
                        rx_frame_start <= first_data_byte;
                        first_data_byte <= 0;
                    end

                    DROP: begin
                     if (!rx_dv) begin  //the rx_dv is the input signal that will be deaserted between frames, if the DROP state was called, it means that we are inside a bad frame
                                        //and that means that we will stay in the DROP state and ignore all the incoming bytes till the rx_dv is deasserted indicating that the bad frame is over
                                        //after this the code will go back to the idle state where we will again start the process of checking the new packet.
                     state <= IDLE;
                     pre_cnt <= 0;
                     end
                    end
                endcase     
            end
        end
    end

endmodule

// ❌ No CRC/FCS check (mandatory in Ethernet MAC)

// ❌ rx_er ignored (PHY error should drop frame)


// ⚠️ Preamble count should be exactly 7 bytes, not >=6

// said that MAC do >=6 to allow for jitter or noise, but for strict IEEE compliance it should be "=7" there nothing else

// ⚠️ No minimum/maximum frame length check

// ⚠️ No MAC address filtering (promiscuous only)