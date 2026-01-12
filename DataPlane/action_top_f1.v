`timescale 1ns / 1ps

module action_top (
    input        clk,
    input        rst_n,


    input        rx_valid,
    input [7:0]  rx_data,
    input        rx_last,

   
    input              tcam_wr_en,
    input              tcam_wr_is_mask,
    input  [3:0]       tcam_wr_addr,   // log2(16)
    input  [127:0]     tcam_wr_data,

 
    input              action_wr_en,
    input  [3:0]       action_wr_addr,
    input  [63:0]      action_wr_data,
     output [63:0] action_out,


    output       rx_ready,


    output       parse_done,

    output       tcam_hit,
    output [3:0] tcam_hit_index   // ENTRIES=16

   

);

 
    wire [8*192-1:0] header_flat;
    wire             header_done;
    wire [8:0]       header_len;


   wire        tcam_hit_c;
    wire [3:0]  tcam_hit_index_c;



    
    wire [47:0] src_mac;
    wire [47:0] dst_mac;
    wire        has_vlan;
    wire [11:0] vlan_id;

    
    wire        is_ipv4;
    wire        is_ipv6;
    wire        is_arp;

    wire [31:0] src_ip;
    wire [31:0] dst_ip;

    wire [7:0]  ttl;
    wire [5:0]  dscp;
    wire [1:0]  ecn;
    wire        is_fragmented;

    
    wire [7:0]  ip_proto;
    wire [15:0] src_port;
    wire [15:0] dst_port;
    wire [7:0]  tcp_flags;
    wire [7:0]  icmp_type;

    
    wire [63:0] action;

    wire [127:0] tcam_key;


    header_buffer u_buf (
        .clk(clk),
        .rst_n(rst_n),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .rx_last(rx_last),
        .rx_ready(rx_ready),
        .header_flat(header_flat),
        .header_len(header_len),
        .header_done(header_done)
    );


    packet_parser_gold u_parser (
        .clk(clk),
        .rst_n(rst_n),
        .header_done(header_done),
        .header_flat(header_flat),

        .src_mac(src_mac),
        .dst_mac(dst_mac),
        .has_vlan(has_vlan),
        .vlan_id(vlan_id),

        .is_ipv4(is_ipv4),
        .is_ipv6(is_ipv6),
        .is_arp(is_arp),
        .src_ip(src_ip),
        .dst_ip(dst_ip),
        .ttl(ttl),
        .dscp(dscp),
        .ecn(ecn),
        .is_fragmented(is_fragmented),

        .ip_proto(ip_proto),
        .src_port(src_port),
        .dst_port(dst_port),
        .tcp_flags(tcp_flags),
        .icmp_type(icmp_type),

        .parse_done(parse_done)
    );

  
    key_builder u_key_builder (
        .src_ip(src_ip),
        .dst_ip(dst_ip),
        .ip_proto(ip_proto),
        .src_port(src_port),
        .dst_port(dst_port),
        .vlan_id(vlan_id),
        .dscp(dscp),
        .is_ipv4(is_ipv4),
        .is_ipv6(is_ipv6),
        .is_arp(is_arp),
        .is_fragmented(is_fragmented),
        .tcam_key(tcam_key)
    );

    tcam_ctrl #(
        .KEY_W(128),
        .ENTRIES(16)
    ) u_tcam (
        .clk(clk),
        .rst_n(rst_n),

        
        .key(tcam_key),
        .key_valid(parse_done),

        
        .wr_en(tcam_wr_en),
        .wr_is_mask(tcam_wr_is_mask),
        .wr_addr(tcam_wr_addr),
        .wr_data(tcam_wr_data),

        
        .hit(tcam_hit_c),
        .hit_index(tcam_hit_index_c)
    );

    reg        tcam_hit_r;
    reg [3:0]  tcam_hit_index_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tcam_hit_r       <= 1'b0;
            tcam_hit_index_r <= 4'd0;
        end else if (parse_done) begin
            tcam_hit_r       <= tcam_hit_c;
            tcam_hit_index_r <= tcam_hit_index_c;
        end
    end

    assign tcam_hit       = tcam_hit_r;
    assign tcam_hit_index = tcam_hit_index_r;

    action_mem #(
    .ENTRIES(16),
    .ACTION_W(64)
) u_action (
    .clk(clk),

    
    .rd_en(tcam_hit),
    .rd_addr(tcam_hit_index),
    .rd_data(action),

 
    .wr_en(action_wr_en),
    .wr_addr(action_wr_addr),
    .wr_data(action_wr_data)
);

assign action_out = action;





endmodule
