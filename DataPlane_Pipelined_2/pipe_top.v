`timescale 1ns / 1ps
module pipe_top #(
    parameter HEADER_BYTES = 192,
    parameter FIFO_DEPTH   = 16,
    parameter FIFO_ADDR_W  = 4,
    parameter TCAM_ENTRIES = 16,
    parameter ACTION_W     = 64
)(
    input  wire clk,
    input  wire rst_n,

    // ===== MAC RX interface =====
    input  wire        mac_rx_valid,
    input  wire [7:0]  mac_rx_data,
    input  wire        mac_rx_last,
    output wire        mac_rx_ready,

    // ===== Control plane (TCAM + actions) =====
    input  wire                         tcam_wr_en,
    input  wire                         tcam_wr_is_mask,
    input  wire [$clog2(TCAM_ENTRIES)-1:0] tcam_wr_addr,
    input  wire [127:0]                 tcam_wr_data,

    input  wire                         action_wr_en,
    input  wire [$clog2(TCAM_ENTRIES)-1:0] action_wr_addr,
    input  wire [ACTION_W-1:0]          action_wr_data,

    input  wire                         action_wr_default,
    input  wire [ACTION_W-1:0]          action_default_data,

    // ===== Final decision output =====
    output wire                         action_valid,
    output wire [ACTION_W-1:0]          action
);


wire fifo_valid, fifo_ready;
wire [7:0] fifo_data;
wire fifo_last;

wire fifo_fire;

mac_rx_fifo #(
    .DEPTH (FIFO_DEPTH),
    .ADDR_W(FIFO_ADDR_W)
) u_mac_rx_fifo (
    .clk       (clk),
    .rst_n     (rst_n),

    .rx_valid  (mac_rx_valid),
    .rx_data   (mac_rx_data),
    .rx_last   (mac_rx_last),
    .rx_ready  (mac_rx_ready),

    .fifo_valid(fifo_valid),
    .fifo_data (fifo_data),
    .fifo_last (fifo_last),
    .fifo_ready(fifo_ready),

    .fifo_fire(fifo_fire)
);


wire header_valid, header_ready;
wire [8*HEADER_BYTES-1:0] header_flat;
wire [8:0] header_len; // unused downstream but kept

header_buffer_pipe_fifo #(
    .HEADER_BYTES(HEADER_BYTES),
    .PTR_W(8)
) u_header_buffer_pipe_fifo (
    .clk         (clk),
    .rst_n       (rst_n),

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

wire hdr_valid, hdr_ready;
wire [8*HEADER_BYTES-1:0] hdr_flat;

header_to_parser_pipe_reg #(
    .HEADER_BYTES(HEADER_BYTES),
    .PTR_W(8)
) u_header_to_parser_pipe_reg (
    .clk         (clk),
    .rst_n       (rst_n),

    .header_valid(header_valid),
    .header_flat (header_flat),
    .header_len  (header_len),
    .header_ready(header_ready),

    .hdr_valid   (hdr_valid),
    .hdr_flat    (hdr_flat),
    .hdr_ready   (hdr_ready)
);



wire parser_valid, parser_ready;

wire [31:0] src_ip, dst_ip;
wire [7:0]  ip_proto;
wire [15:0] src_port, dst_port;
wire [11:0] vlan_id;
wire [5:0]  dscp;
wire        is_ipv4, is_ipv6, is_arp, is_fragmented;

parser_fsm_pipe u_parser_fsm_pipe (
    .clk        (clk),
    .rst_n      (rst_n),

    .hdr_valid  (hdr_valid),
    .hdr_flat   (hdr_flat),
    .hdr_ready  (hdr_ready),

    .src_ip     (src_ip),
    .dst_ip     (dst_ip),
    .ip_proto   (ip_proto),
    .src_port   (src_port),
    .dst_port   (dst_port),
    .vlan_id    (vlan_id),
    .dscp       (dscp),
    .is_ipv4    (is_ipv4),
    .is_ipv6    (is_ipv6),
    .is_arp     (is_arp),
    .is_fragmented(is_fragmented),

    .parser_valid(parser_valid),
    .parser_ready(parser_ready)
);


wire key_valid, key_ready;
wire [127:0] tcam_key;

parser_to_key_pipe u_parser_to_key_pipe (
    .clk        (clk),
    .rst_n      (rst_n),

    .parser_valid(parser_valid),
    .parser_ready(parser_ready),

    .src_ip     (src_ip),
    .dst_ip     (dst_ip),
    .ip_proto   (ip_proto),
    .src_port   (src_port),
    .dst_port   (dst_port),
    .vlan_id    (vlan_id),
    .dscp       (dscp),
    .is_ipv4    (is_ipv4),
    .is_ipv6    (is_ipv6),
    .is_arp     (is_arp),
    .is_fragmented(is_fragmented),

    .key_valid  (key_valid),
    .key_ready  (key_ready),

    .key_src_ip (),
    .key_dst_ip (),
    .key_ip_proto(),
    .key_src_port(),
    .key_dst_port(),
    .key_vlan_id(),
    .key_dscp   (),
    .key_is_ipv4(),
    .key_is_ipv6(),
    .key_is_arp (),
    .key_is_fragmented()
);


key_builder_pipe u_key_builder_pipe (
    .src_ip     (src_ip),
    .dst_ip     (dst_ip),
    .ip_proto   (ip_proto),
    .src_port   (src_port),
    .dst_port   (dst_port),
    .vlan_id    (vlan_id),
    .dscp       (dscp),
    .is_ipv4    (is_ipv4),
    .is_ipv6    (is_ipv6),
    .is_arp     (is_arp),
    .is_fragmented(is_fragmented),
    .tcam_key   (tcam_key)
);


wire tcam_hit;
wire [$clog2(TCAM_ENTRIES)-1:0] tcam_hit_index;

assign key_ready = 1'b1; // TCAM always ready

tcam_ctrl_pipe #(
    .KEY_W   (128),
    .ENTRIES (TCAM_ENTRIES)
) u_tcam_ctrl_pipe (
    .clk        (clk),
    .rst_n      (rst_n),

    .key        (tcam_key),
    .key_valid  (key_valid),

    .wr_en      (tcam_wr_en),
    .wr_is_mask (tcam_wr_is_mask),
    .wr_addr    (tcam_wr_addr),
    .wr_data    (tcam_wr_data),

    .hit        (tcam_hit),
    .hit_index  (tcam_hit_index)
);


wire action_pipe_valid, action_pipe_ready;
wire action_hit;
wire [$clog2(TCAM_ENTRIES)-1:0] action_index;

tcam_to_action_pipe u_tcam_to_action_pipe (
    .clk         (clk),
    .rst_n       (rst_n),

    .tcam_valid  (key_valid),
    .tcam_hit    (tcam_hit),
    .tcam_hit_index(tcam_hit_index),
    .tcam_ready  (),

    .action_valid(action_pipe_valid),
    .action_ready(1'b1),
    .action_hit  (action_hit),
    .action_index(action_index)
);


action_pipe #(
    .ENTRIES (TCAM_ENTRIES),
    .ACTION_W(ACTION_W)
) u_action_pipe (
    .clk        (clk),
    .rst_n      (rst_n),

    .tcam_valid (action_pipe_valid),
    .hit        (action_hit),
    .hit_index  (action_index),

    .action_valid(action_valid),
    .action     (action),

    .wr_en      (action_wr_en),
    .wr_addr    (action_wr_addr),
    .wr_data    (action_wr_data),

    .wr_default (action_wr_default),
    .default_data(action_default_data)
);

endmodule