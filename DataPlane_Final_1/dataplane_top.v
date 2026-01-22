`timescale 1ns / 1ps
module dataplane_top #(
    parameter HEADER_BYTES = 192,
    parameter PTR_W        = 8,
    parameter KEY_W        = 128,
    parameter ACTION_W     = 64,
    parameter TCAM_ENTRIES = 16,
    parameter PKT_FIFO_DEPTH = 512
)(
    input  wire        clk,
    input  wire        rst_n,

    //frm the bottom fifo (i/p)
    input  wire        rx_valid,
    input  wire [7:0]  rx_data,
    input  wire        rx_last,
    output wire        rx_ready,

    //to the output (egress mac)
    output wire        tx_valid,
    output wire [7:0]  tx_data,
    output wire        tx_last,
    input  wire        tx_ready,

   //ctrl plane signals (picorv)

    // for tcam
    input  wire        cfg_tcam_wr_en,
    input  wire        cfg_tcam_wr_is_mask,
    input  wire [$clog2(TCAM_ENTRIES)-1:0] cfg_tcam_wr_addr,
    input  wire [KEY_W-1:0] cfg_tcam_wr_data,

    // for action
    input  wire        cfg_action_wr_en,
    input  wire [$clog2(TCAM_ENTRIES)-1:0] cfg_action_wr_addr,
    input  wire [ACTION_W-1:0] cfg_action_wr_data,

    input  wire        cfg_action_wr_default,
    input  wire [ACTION_W-1:0] cfg_action_default_data
);


    //fifo btw mac nd hdr buffer

    wire        fifo_valid;
    wire [7:0]  fifo_data;
    wire        fifo_last;
    wire        fifo_ready;
    wire fifo_fire;

    wire rx_ready_hdr;
    wire rx_ready_pkt;

    assign rx_ready = rx_ready_hdr && rx_ready_pkt;

    mac_rx_fifo_final u_mac_rx_fifo_final (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_valid   (rx_valid),
        .rx_data    (rx_data),
        .rx_last    (rx_last),
        .rx_ready   (rx_ready_hdr),
        .fifo_valid (fifo_valid),
        .fifo_data  (fifo_data),
        .fifo_last  (fifo_last),
        .fifo_ready (fifo_ready),
        .fifo_fire (fifo_fire)
    );

    //hdr buffer
    wire [8*HEADER_BYTES-1:0] header_flat;
    wire [PTR_W:0]            header_len;
    wire                       header_valid;
    wire                       header_ready;

    header_buffer_pipe_fifo u_header_buffer_pipe_fifo (
        .clk          (clk),
        .rst_n        (rst_n),
        .fifo_valid  (fifo_valid),
        .fifo_data   (fifo_data),
        .fifo_last   (fifo_last),
        .fifo_ready  (fifo_ready),
        .fifo_fire  (fifo_fire),
        .header_flat (header_flat),
        .header_len  (header_len),
        .header_valid(header_valid),
        .header_ready(header_ready)
    );

    //hdr to parse pipe reg
    wire hdr_valid;
    wire hdr_ready;
    wire [8*HEADER_BYTES-1:0] hdr_flat;

    header_to_parser_pipe_reg u_header_to_parser_pipe_reg (
        .clk          (clk),
        .rst_n        (rst_n),
        .header_valid (header_valid),
        .header_flat  (header_flat),
        .header_len   (header_len),
        .header_ready (header_ready),
        .hdr_valid    (hdr_valid),
        .hdr_flat     (hdr_flat),
        .hdr_ready    (hdr_ready)
    );

    //parser fsm
    wire parser_valid;
    wire parser_ready = 1'b1; // next stage is combinational

    wire pkt_start, pkt_end;
    wire [15:0] l2_offset, l3_offset, l4_offset;
    wire [7:0]  ip_hdr_len;
    wire [15:0] header_len_out;

    wire [31:0] src_ip, dst_ip;
    wire [7:0]  ip_proto;
    wire [15:0] src_port, dst_port;
    wire [5:0]  dscp;
    wire [11:0] vlan_id;
    wire        is_ipv4, is_ipv6, is_arp, is_fragmented;

    parser_fsm_pipe_2 u_parser_fsm_pipe_2 (
        .clk          (clk),
        .rst_n        (rst_n),
        .hdr_valid    (hdr_valid),
        .hdr_flat     (hdr_flat),
        .hdr_ready    (hdr_ready),
        .parser_valid (parser_valid),
        .parser_ready (parser_ready),

        .pkt_start    (pkt_start),
        .pkt_end      (pkt_end),

        .l2_offset    (l2_offset),
        .l3_offset    (l3_offset),
        .l4_offset    (l4_offset),
        .ip_hdr_len   (ip_hdr_len),
        .header_len   (header_len_out),

        .src_ip       (src_ip),
        .dst_ip       (dst_ip),
        .ip_proto     (ip_proto),
        .src_port     (src_port),
        .dst_port     (dst_port),
        .dscp         (dscp),
        .vlan_id      (vlan_id),
        .is_ipv4      (is_ipv4),
        .is_ipv6      (is_ipv6),
        .is_arp       (is_arp),
        .is_fragmented(is_fragmented)
    );

    //key builder
    wire [KEY_W-1:0] tcam_key;

    key_builder_pipe u_key_builder_pipe (
        .src_ip        (src_ip),
        .dst_ip        (dst_ip),
        .ip_proto      (ip_proto),
        .src_port      (src_port),
        .dst_port      (dst_port),
        .vlan_id       (vlan_id),
        .dscp          (dscp),
        .is_ipv4       (is_ipv4),
        .is_ipv6       (is_ipv6),
        .is_arp        (is_arp),
        .is_fragmented (is_fragmented),
        .tcam_key      (tcam_key)
    );

    //tcam
    wire tcam_hit;
    wire [$clog2(TCAM_ENTRIES)-1:0] hit_index;

   tcam_ctrl_pipe u_tcam_ctrl_pipe (
    .clk        (clk),
    .rst_n      (rst_n),

    .key        (tcam_key),
    .key_valid  (parser_valid),

    .hit        (tcam_hit),
    .hit_index  (hit_index),

    // control plane
    .wr_en      (cfg_tcam_wr_en),
    .wr_is_mask (cfg_tcam_wr_is_mask),
    .wr_addr    (cfg_tcam_wr_addr),
    .wr_data    (cfg_tcam_wr_data)
);

    //action
    wire action_valid;
    wire [ACTION_W-1:0] action;

   action_pipe u_action_pipe (
    .clk          (clk),
    .rst_n        (rst_n),

    .tcam_valid   (parser_valid),
    .hit          (tcam_hit),
    .hit_index    (hit_index),

    .action_valid (action_valid),
    .action       (action),

    // control plane
    .wr_en        (cfg_action_wr_en),
    .wr_addr      (cfg_action_wr_addr),
    .wr_data      (cfg_action_wr_data),

    .wr_default   (cfg_action_wr_default),
    .default_data (cfg_action_default_data)
);


    //upper part of the pipeline

    //action drain control
    wire allow_drain;
    wire [ACTION_W-1:0] action_latched;
    wire pkt_start_latched;

    
    wire        rewrite_in_ready;

    
    wire        rewrite_out_valid;
    wire [7:0]  rewrite_out_data;
    wire        rewrite_out_last;
    wire        rewrite_out_ready;
    wire pkt_sop;

action_drain_ctrl_upper u_action_drain_ctrl_upper (
    .clk              (clk),
    .rst_n            (rst_n),

    .action_valid     (action_valid),
    .action_in        (action),

    .pkt_start_in     (pkt_start),

    //.fifo_pkt_done    (fifo_pkt_done),

    .allow_drain      (allow_drain),
    .action_latched   (action_latched),
    .pkt_start_latched(pkt_start_latched)
);
    


//pkt fifo for entire pkt
wire        pf_rd_valid;
wire [7:0]  pf_rd_data;
wire        pf_rd_last;

packet_fifo_upper #(
    .DEPTH (PKT_FIFO_DEPTH)
) u_packet_fifo_upper (
    .clk        (clk),
    .rst_n      (rst_n),

    
    .wr_valid   (fifo_fire && fifo_valid),
    .wr_data    (fifo_data),
    .wr_last    (fifo_last),
    .wr_ready   (rx_ready_pkt),

    
    .rd_valid   (pf_rd_valid),
    .rd_data    (pf_rd_data),
    .rd_last    (pf_rd_last),
    .rd_ready   (rewrite_in_ready),

    .allow_drain(allow_drain),

    .pkt_sop (pkt_sop)
);
    
   //rewrite mux 
   rewrite_mux_upper u_rewrite_mux_upper (
    .clk       (clk),
    .rst_n     (rst_n),

    .in_valid  (pf_rd_valid),
    .in_data   (pf_rd_data),
    .in_last   (pf_rd_last),
    .in_ready  (rewrite_in_ready),

    .pkt_sop   (pkt_sop),          
    .action    (action_latched),

    .l2_offset (l2_offset),
    .l3_offset (l3_offset),
    .l4_offset (l4_offset),

    .out_valid (rewrite_out_valid),
    .out_data  (rewrite_out_data),
    .out_last  (rewrite_out_last),
    .out_ready (rewrite_out_ready)
);

    assign tx_valid = rewrite_out_valid;
assign tx_data  = rewrite_out_data;
assign tx_last  = rewrite_out_last;

assign rewrite_out_ready = tx_ready;


endmodule
