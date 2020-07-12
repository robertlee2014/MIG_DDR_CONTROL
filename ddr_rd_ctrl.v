`timescale 1ns / 1ps
module ddr_rd_ctrl(
    input  wire         ui_clk,
    input  wire         rst,
    input  wire         rd_start,

    output wire         rd_req,
    input  wire         rd_ack,
    output wire         rd_done,
    output wire         rd_busy,

    output wire [2:0]   app_cmd,
    output wire         app_en,
    output wire [28:0]  app_addr,
    input  wire         app_rdy,

    input  wire         app_rd_data_vld,
    input  wire [255:0] app_rd_data,
    output wire         rd_ddr_data_vld,
    output wire [255:0] rd_ddr_data
);
//parameter define
parameter IDLE        = 3'b001;
parameter RD_REQ      = 3'b010;
parameter READ        = 3'b100;

parameter TOTAL_PIXEL = 1024*768 - 8;
parameter BURST_LEN   = 64-1;
//internal signal
reg  [2:0]   state;

reg  [9:0]   cnt_data;
wire         add_cnt_data;
wire         end_cnt_data;
reg  [9:0]   cnt_cmd;
wire         add_cnt_cmd;
wire         end_cnt_cmd;

reg          app_en_r;
reg  [28:0]  app_addr_r;

reg          rd_done_r;
reg          rd_req_r;
reg          rd_ddr_data_vld_r;
reg  [255:0] rd_ddr_data_r;

assign app_cmd         = 3'b001;
assign app_en          = app_en_r;
assign app_addr        = app_addr_r;
assign rd_done         = rd_done_r;
assign rd_busy         = state == READ;
assign rd_req          = rd_req_r;
assign rd_ddr_data     = rd_ddr_data_r;
assign rd_ddr_data_vld = rd_ddr_data_vld_r;
//state machine
always @(posedge ui_clk) begin
    if (rst) begin
        state <= IDLE;
    end
    else begin
        case (state)
            IDLE:begin
                if (rd_start) state <= RD_REQ;
                else state <= IDLE;
            end 
            RD_REQ:begin
                if (rd_ack) state <= READ;
                else state <= RD_REQ;
            end
            READ:begin
                if (end_cnt_cmd) state <= IDLE;
                else state <= READ;
            end
            default: state <= IDLE;
        endcase
    end
end
//cnt_data
always @(posedge ui_clk) begin
    if (rst) begin
        cnt_data <= 0;
    end
    else if (add_cnt_data) begin
        if (end_cnt_data) cnt_data <= 0;
        else cnt_data <= cnt_data + 1'b1;
    end
end

assign add_cnt_data = app_rd_data_vld;
assign end_cnt_data = add_cnt_data && cnt_data == BURST_LEN;
//app_en_r
always @(posedge ui_clk) begin
    if (rst) begin
        app_en_r <= 1'b0;
    end
    else if (end_cnt_cmd) begin
        app_en_r <= 1'b0;
    end
    else if (state == RD_REQ && rd_ack) begin
        app_en_r <= 1'b1;
    end
end
//cnt_cmd
always @(posedge ui_clk) begin
    if (rst) begin
        cnt_cmd <= 0;
    end
    else if (add_cnt_cmd) begin
        if (end_cnt_cmd) begin
            cnt_cmd <= 0;
        end
        else cnt_cmd <= cnt_cmd + 1'b1;
    end
end

assign add_cnt_cmd = app_rdy & app_en_r;
assign end_cnt_cmd = add_cnt_cmd && cnt_cmd == BURST_LEN;

//app_addr_r
always @(posedge ui_clk) begin
    if (rst) begin
        app_addr_r <= 0;
    end
    else if (app_addr_r == TOTAL_PIXEL && app_en_r && app_rdy) begin
        app_addr_r <= 'd0;
    end
    else if (app_en_r && app_rdy) begin
        app_addr_r <= app_addr_r + 'd8;
    end
end
//rd_done_r
always @(posedge ui_clk) begin
    if (rst) begin
        rd_done_r <= 1'b0;
    end
    else if (end_cnt_cmd) begin
        rd_done_r <= 1'b1;
    end
    else rd_done_r <= 1'b0;
end
//rd_req_r
always @(posedge ui_clk) begin
    if (rst) begin
        rd_req_r <= 1'b0;
    end
    else if (rd_ack) begin
        rd_req_r <= 1'b0;
    end
    else if (state == IDLE && rd_start) begin
        rd_req_r <= 1'b1;
    end
end
//rd_ddr_data_r,rd_ddr_data-vld_r
always @(posedge ui_clk) begin
    if (rst) begin
        rd_ddr_data_r     <= 'd0;
        rd_ddr_data_vld_r <= 1'b0;
    end
    else begin
        rd_ddr_data_r     <= app_rd_data;
        rd_ddr_data_vld_r <= app_rd_data_vld;
    end
end
endmodule //ddr_rd_ctrl