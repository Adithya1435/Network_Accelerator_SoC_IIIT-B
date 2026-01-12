`timescale 1ns / 1ps

module tb_action;

    reg clk;
    reg rst_n;

    reg        rx_valid;
    reg [7:0]  rx_data;
    reg        rx_last;


    reg        tcam_wr_en;
    reg        tcam_wr_is_mask;
    reg [3:0]  tcam_wr_addr;
    reg [127:0] tcam_wr_data;


   
    reg        action_wr_en;
    reg [3:0]  action_wr_addr;
    reg [63:0] action_wr_data;
    wire [63:0] action_out;


    wire rx_ready;
    wire parse_done;
    wire tcam_hit;
    wire [3:0] tcam_hit_index;

    
    action_top dut (
        .clk(clk),
        .rst_n(rst_n),

        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .rx_last(rx_last),
        .rx_ready(rx_ready),

        .parse_done(parse_done),

        .tcam_hit(tcam_hit),
        .tcam_hit_index(tcam_hit_index),

        .tcam_wr_en(tcam_wr_en),
        .tcam_wr_is_mask(tcam_wr_is_mask),
        .tcam_wr_addr(tcam_wr_addr),
        .tcam_wr_data(tcam_wr_data),

        .action_wr_en(action_wr_en),
        .action_wr_addr(action_wr_addr),
        .action_wr_data(action_wr_data),
        .action_out(action_out)

    );

   
    always #5 clk = ~clk;

    reg [7:0] packet [0:53];
    integer i;

    task tcam_write;
        input [3:0]   addr;
        input         is_mask;
        input [127:0] data;
        begin
            @(posedge clk);
            tcam_wr_en      <= 1'b1;
            tcam_wr_addr    <= addr;
            tcam_wr_is_mask <= is_mask;
            tcam_wr_data    <= data;

            @(posedge clk);
            tcam_wr_en <= 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        rx_valid = 0;
        rx_data  = 0;
        rx_last  = 0;

        tcam_wr_en = 0;
        tcam_wr_is_mask = 0;
        tcam_wr_addr = 0;
        tcam_wr_data = 0;

        action_wr_en   = 0;
        action_wr_addr = 0;
        action_wr_data = 0;



        packet[0]=8'hAA; packet[1]=8'hBB; packet[2]=8'hCC;
        packet[3]=8'hDD; packet[4]=8'hEE; packet[5]=8'hFF;
        packet[6]=8'h11; packet[7]=8'h22; packet[8]=8'h33;
        packet[9]=8'h44; packet[10]=8'h55; packet[11]=8'h66;
        packet[12]=8'h08; packet[13]=8'h00;

        packet[14]=8'h45;
        packet[15]=8'h00;
        packet[16]=8'h00; packet[17]=8'h28;
        packet[18]=8'h00; packet[19]=8'h00;
        packet[20]=8'h00; packet[21]=8'h00;
        packet[22]=8'h40;
        packet[23]=8'h06;
        packet[24]=8'h00; packet[25]=8'h00;
        packet[26]=8'hC0; packet[27]=8'hA8;
        packet[28]=8'h01; packet[29]=8'h0A;
        packet[30]=8'h08; packet[31]=8'h08;
        packet[32]=8'h08; packet[33]=8'h08;

        packet[34]=8'h04; packet[35]=8'hD2;
        packet[36]=8'h00; packet[37]=8'h50; 
        packet[38]=8'h00; packet[39]=8'h00;
        packet[40]=8'h00; packet[41]=8'h00;
        packet[42]=8'h00; packet[43]=8'h00;
        packet[44]=8'h00; packet[45]=8'h00;
        packet[46]=8'h50;
        packet[47]=8'h02;
        packet[48]=8'h20; packet[49]=8'h00;
        packet[50]=8'h00; packet[51]=8'h00;
        packet[52]=8'h00; packet[53]=8'h00;


        #20 rst_n = 1;

   

        
        tcam_write(4'd0, 0, {
            32'h0,32'h0,8'd6,16'h0,16'd22,
            12'h0,6'h0,1'b1,1'b0,1'b0,1'b0,2'b00
        });
        tcam_write(4'd0, 1, {
            32'hFFFFFFFF,32'hFFFFFFFF,8'h00,16'hFFFF,16'h0000,
            12'hFFF,6'h3F,1'b0,1'b1,1'b1,1'b1,2'b11
        });

 
        tcam_write(4'd2, 0, {
            32'h0,32'h0,8'd6,16'h0,16'd80,
            12'h0,6'h0,1'b1,1'b0,1'b0,1'b0,2'b00
        });
        tcam_write(4'd2, 1, {
            32'hFFFFFFFF,32'hFFFFFFFF,8'h00,16'hFFFF,16'h0000,
            12'hFFF,6'h3F,1'b0,1'b1,1'b1,1'b1,2'b11
        });

 
        tcam_write(4'd4, 0, {
            32'h0,32'h0,8'd6,16'h0,16'h0,
            12'h0,6'h0,1'b1,1'b0,1'b0,1'b0,2'b00
        });
        tcam_write(4'd4, 1, {
            32'hFFFFFFFF,32'hFFFFFFFF,8'h00,16'hFFFF,16'hFFFF,
            12'hFFF,6'h3F,1'b0,1'b1,1'b1,1'b1,2'b11
        });


        @(posedge clk);
        action_wr_en   <= 1'b1;
        action_wr_addr <= 4'd0;
        action_wr_data <= 64'h0000_0000_0000_0001; 

        @(posedge clk);
        action_wr_en <= 1'b0;

    
        @(posedge clk);
        action_wr_en   <= 1'b1;
        action_wr_addr <= 4'd2;
        action_wr_data <= 64'h0000_0000_0000_0002; 

        @(posedge clk);
        action_wr_en <= 1'b0;

   
        @(posedge clk);
        action_wr_en   <= 1'b1;
        action_wr_addr <= 4'd4;
        action_wr_data <= 64'h0000_0000_0000_0003; 

        @(posedge clk);
        action_wr_en <= 1'b0;


        #20;
        for (i = 0; i < 54; i = i + 1) begin
            @(posedge clk);
            rx_valid <= 1'b1;
            rx_data  <= packet[i];
            rx_last  <= (i == 53);
        end

        @(posedge clk);
        rx_valid <= 0;
        rx_last  <= 0;

        wait (parse_done);

        #100;
        $finish;
    end

    initial begin
        $dumpfile("action.vcd");
        $dumpvars(0, tb_action);
    end

endmodule
