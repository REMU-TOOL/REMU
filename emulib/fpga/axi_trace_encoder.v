`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module axi_trace_encoder #(
    parameter   A_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   R_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   W_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   B_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   CHANNEL_SEQ     = 0
)(
    (* __emu_common_port = "mdl_clk" *)
    input wire  mdl_clk,
    (* __emu_common_port = "mdl_rst" *)
    input wire  mdl_rst,
    input wire  clk,

    // Reset Channel

    (* __emu_channel_name = "rst"*)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "rst" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_rst_valid" *)
    (* __emu_channel_ready = "tk_rst_ready" *)

    input  wire                     tk_rst_valid,
    output wire                     tk_rst_ready,

    input  wire                     rst,
    

    (* __emu_channel_name = "ar_log" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "logging_ar*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_arlog_valid" *)
    (* __emu_channel_ready = "tk_arlog_ready" *)

    input  wire  tk_arlog_valid,
    output wire  tk_arlog_ready,
    input  wire  logging_arvalid,
    output wire  logging_arready,
    input  wire  [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_ar_payload,

    (* __emu_channel_name = "aw_log" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "logging_aw*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_awlog_valid" *)
    (* __emu_channel_ready = "tk_awlog_ready" *)

    input  wire  tk_awlog_valid,
    output wire  tk_awlog_ready,
    input  wire  logging_awvalid,
    output wire  logging_awready,
    input  wire  [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_aw_payload,

    (* __emu_channel_name = "w_log" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "logging_w*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_wlog_valid" *)
    (* __emu_channel_ready = "tk_wlog_ready" *)

    input  wire  tk_wlog_valid,
    output wire  tk_wlog_ready,
    input  wire  logging_wvalid,
    output wire  logging_wready,
    input  wire  [W_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_w_payload,

    (* __emu_channel_name = "b_log" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "logging_b*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_blog_valid" *)
    (* __emu_channel_ready = "tk_blog_ready" *)

    input  wire  tk_blog_valid,
    output wire  tk_blog_ready,
    input  wire  logging_bvalid,
    output wire  logging_bready,
    input  wire  [B_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_b_payload,

    (* __emu_channel_name = "r_log" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "logging_r*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_rlog_valid" *)
    (* __emu_channel_ready = "tk_rlog_ready" *)

    input  wire  tk_rlog_valid,
    output wire  tk_rlog_ready,
    input  wire  logging_rvalid,
    output wire  logging_rready,
    input  wire  [R_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_r_payload,

    output wire                             o_valid,
    input  wire                             o_ready,
    output wire [512/8-1:0]                 o_keep,
    output wire [512-1:0]                   o_data,
    output wire                             o_last
);
    localparam PACKAGE_LEN = A_PAYLOAD_FORMANTTED_WIDTH*2 + R_PAYLOAD_FORMANTTED_WIDTH + W_PAYLOAD_FORMANTTED_WIDTH + B_PAYLOAD_FORMANTTED_WIDTH;
    
    reg [A_PAYLOAD_FORMANTTED_WIDTH-1:0] ar_log_data;
    reg [A_PAYLOAD_FORMANTTED_WIDTH-1:0] aw_log_data;
    reg [R_PAYLOAD_FORMANTTED_WIDTH-1:0] r_log_data;
    reg [W_PAYLOAD_FORMANTTED_WIDTH-1:0] w_log_data;
    reg [B_PAYLOAD_FORMANTTED_WIDTH-1:0] b_log_data;

    reg [3:0] package_counter;
    wire pkg_i_valid;
    wire pkg_i_ready;
    wire trace_disable = 0;
    wire [PACKAGE_LEN-1:0] pkg_data;
    reg [4:0] sel_o_valid;

    assign pkg_i_valid = |{logging_wvalid&&logging_wready, logging_arready && logging_arvalid, 
            logging_awvalid && logging_awready, logging_rready && logging_rvalid, logging_bready && logging_bvalid};
    assign pkg_i_ready = package_counter == 0 && o_ready;

    
    always @(posedge clk) begin
        if (rst) begin
            package_counter <= 0;
        end
        else if (pkg_i_valid && pkg_i_ready) begin
            package_counter <= PACKAGE_LEN/512 + ((PACKAGE_LEN%512) != 0);
        end 
        else if (o_valid && o_ready) 
            package_counter <= package_counter - 1;
    end
    always @(posedge clk) begin
        if (rst) begin
            ar_log_data <= 0;
            sel_o_valid[0] <= 0;
        end
        else if(logging_arready && logging_arvalid && pkg_i_ready) begin
            ar_log_data <= logging_ar_payload;
            sel_o_valid[0] <= 1;
        end
        else if(package_counter == 0)
            sel_o_valid[0] <= 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            sel_o_valid[1] <= 0;
            aw_log_data <= 0;
        end
        else if(logging_awready && logging_awvalid && pkg_i_ready) begin
            sel_o_valid[1] <= 1;
            aw_log_data <= logging_aw_payload;
        end
        else if(package_counter == 0)
            sel_o_valid[1] <= 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            sel_o_valid[2] <= 0;
            r_log_data <= 0;
        end
        else if(logging_rready && logging_rvalid && pkg_i_ready) begin
            sel_o_valid[2] <= 1;
            r_log_data <= logging_r_payload;
        end
        else if(package_counter == 0)
            sel_o_valid[2] <= 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            sel_o_valid[3] <= 0;
            w_log_data <= 0;
        end
        else if(logging_wready && logging_wvalid && pkg_i_ready) begin
            w_log_data <= logging_w_payload;
            sel_o_valid[3] <= 1;
        end
        else if(package_counter == 0)
            sel_o_valid[3] <= 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            sel_o_valid[4] <= 0;
            b_log_data <= 0;
        end
        else if(logging_bready && logging_bvalid && pkg_i_ready) begin
            sel_o_valid[4] <= 1;
            b_log_data <= logging_b_payload;
        end
        else if(package_counter == 0)
            sel_o_valid[4] <= 0;
    end
    
    assign o_keep = (package_counter != 0)? 64'hffffffffffffffff : 0;
    assign o_valid = package_counter != 0;
    assign o_last = trace_disable;
    assign o_data = (package_counter != 0) ? pkg_data[(package_counter-1)*512+:512] : 0;

    assign pkg_data = { {A_PAYLOAD_FORMANTTED_WIDTH{sel_o_valid[0]}} & ar_log_data, {A_PAYLOAD_FORMANTTED_WIDTH{sel_o_valid[1]}} & aw_log_data, 
                        {R_PAYLOAD_FORMANTTED_WIDTH{sel_o_valid[2]}} & r_log_data, {W_PAYLOAD_FORMANTTED_WIDTH{sel_o_valid[3]}} & w_log_data, 
                        {B_PAYLOAD_FORMANTTED_WIDTH{sel_o_valid[4]}} & b_log_data};
    
    assign {tk_arlog_ready, tk_awlog_ready, tk_rlog_ready, tk_wlog_ready, tk_blog_ready} = {5{pkg_i_ready | !pkg_i_valid}};
endmodule