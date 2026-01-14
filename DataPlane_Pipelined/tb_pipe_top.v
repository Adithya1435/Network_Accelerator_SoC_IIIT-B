`timescale 1ns/1ps

module tb_pipe_top;
integer k;

initial begin
    
    $dumpfile("pipe.vcd");
    // $dumpvars(0, tb_pipe_top);
    $dumpvars(0, tb_pipe_top);

    for (k = 0; k < 16; k = k + 1) begin
        $dumpvars(0, tb_pipe_top.dut.u_mac_rx_fifo.data_mem[k]);
        $dumpvars(0, tb_pipe_top.dut.u_mac_rx_fifo.last_mem[k]);
    end


end

//     initial begin
//     $dumpfile("pipe.vcd");
//     //$dumpvars(0, dut);   // dump EVERYTHING under dut
//     $dumpvars(0, dut.u_mac_rx_fifo);
// end

    reg clk;
    reg rst_n;

    //simulate the mac here
    reg        rx_valid;
    reg [7:0]  rx_data;
    reg        rx_last;
    wire       rx_ready;

    // TCAM control
    reg        tcam_wr_en;
    reg        tcam_wr_is_mask;
    reg [3:0]  tcam_wr_addr;
    reg [127:0] tcam_wr_data;

    // Action control
    reg        action_wr_en;
    reg [3:0]  action_wr_addr;
    reg [63:0] action_wr_data;
    reg        action_wr_default;
    reg [63:0] action_default_data;

    // DUT
    pipe_top dut (
        .clk(clk),
        .rst_n(rst_n),

        .mac_rx_valid(rx_valid),
        .mac_rx_data(rx_data),
        .mac_rx_last(rx_last),
        .mac_rx_ready(rx_ready),

        .tcam_wr_en(tcam_wr_en),
        .tcam_wr_is_mask(tcam_wr_is_mask),
        .tcam_wr_addr(tcam_wr_addr),
        .tcam_wr_data(tcam_wr_data),

        .action_wr_en(action_wr_en),
        .action_wr_addr(action_wr_addr),
        .action_wr_data(action_wr_data),
        .action_wr_default(action_wr_default),
        .action_default_data(action_default_data)
    );

    // Clock: 250 MHz
    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

    // Reset
    initial begin
        rst_n = 0;
        rx_valid = 0;
        rx_data  = 0;
        rx_last  = 0;

        tcam_wr_en = 0;
        action_wr_en = 0;
        action_wr_default = 0;

        #40;
        rst_n = 1;
    end




    // ctrl plane tasks


    task tcam_write_value;
        input [3:0] idx;
        input [127:0] value;
        begin
            @(posedge clk);
            tcam_wr_en = 1;
            tcam_wr_is_mask = 0;
            tcam_wr_addr = idx;
            tcam_wr_data = value;
            @(posedge clk);
            tcam_wr_en = 0;
        end
    endtask

    task tcam_write_mask;
        input [3:0] idx;
        input [127:0] mask;
        begin
            @(posedge clk);
            tcam_wr_en = 1;
            tcam_wr_is_mask = 1;
            tcam_wr_addr = idx;
            tcam_wr_data = mask;
            @(posedge clk);
            tcam_wr_en = 0;
        end
    endtask

    task action_write;
        input [3:0] idx;
        input [63:0] act;
        begin
            @(posedge clk);
            action_wr_en = 1;
            action_wr_addr = idx;
            action_wr_data = act;
            @(posedge clk);
            action_wr_en = 0;
        end
    endtask

    task action_write_default;
        input [63:0] act;
        begin
            @(posedge clk);
            action_wr_default = 1;
            action_default_data = act;
            @(posedge clk);
            action_wr_default = 0;
        end
    endtask

    //mac tasks

    // task send_byte;
    //     input [7:0] b;
    //     input last;
    //     begin
    //         @(posedge clk);
    //         while (!rx_ready) @(posedge clk);
    //         rx_valid = 1;
    //         rx_data  = b;
    //         rx_last  = last;
    //         @(posedge clk);
    //         rx_valid = 0;
    //         rx_last  = 0;
    //     end
    // endtask

    task send_byte;
    input [7:0] b;
    input last;
    
    begin
        rx_valid = 1;
        rx_data  = b;
        rx_last  = last;

        // HOLD until accepted
        while (!(rx_valid && rx_ready))
            @(posedge clk);

        @(posedge clk); // complete handshake
        rx_valid = 0;
        rx_last  = 0;
    end
endtask


//     task send_byte;
//     input [7:0] b;
//     input last;
//     begin
//         rx_valid = 1;
//         rx_data  = b;
//         rx_last  = last;

//         // HOLD until accepted
//         while (!(rx_valid && rx_ready))
//             @(posedge clk);

//         @(posedge clk); // complete handshake
//         rx_valid = 0;
//         rx_last  = 0;
//     end
// endtask


    task send_packet;
        input integer len;
        input [7:0] seed;
        integer i;
        begin
            for (i = 0; i < len; i = i + 1)
                send_byte(seed + i[7:0], (i == len-1));
        end
    endtask

    //test seq
    initial begin
        @(posedge rst_n);
        #20;

        // Match IPv4 TCP (proto = 6)
        //tcam_write_value(0, 128'h00000000_00000000_06_0000_0000_000_00_0000);
        // src_ip, dst_ip ignored
        // ip_proto = 06
        // ports ignored
        // vlan/dscp ignored
        // is_ipv4 = 1
        tcam_write_value(0,
    128'h00000000_00000000_06_0000_0000_000_020
);

        //tcam_write_mask (0, 128'hFFFFFFFF_FFFFFFFF_00_FFFF_FFFF_FFF_FF_FFFF);
        tcam_write_mask(0,
    128'hFFFFFFFF_FFFFFFFF_00_FFFF_FFFF_000_020
);


        // Match IPv4 UDP (proto = 17)
        //tcam_write_value(1, 128'h00000000_00000000_11_0000_0000_000_00_0000);
        tcam_write_value(1,
    128'h00000000_00000000_11_0000_0000_000_020
);

tcam_write_mask(1,
    128'hFFFFFFFF_FFFFFFFF_00_FFFF_FFFF_000_020
);


      
        action_write(0, 64'hAAAA_BBBB_CCCC_DDDD);
        action_write(1, 64'h1111_2222_3333_4444);
        action_write_default(64'hDEAD_DEAD_DEAD_DEAD);

        #43;

       
        $display("Short IPv4 TCP");
        send_packet(64, 8'h10);

        #7;
        $display("Long packet >192 bytes");
        send_packet(300, 8'h40);

        #7;
        $display("Back-to-back packets");
        send_packet(80, 8'h20);
        send_packet(40, 8'h30);
        send_packet(16, 8'h50);

        #500;
        $display("DONE");
        $finish;
    end

endmodule
