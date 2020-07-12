`timescale 1ns / 1ps
module ddr_wr_ctrl(
    input  wire         ui_clk,
    input  wire         rst,
    input  wire         wr_start,
    output wire         data_req,
    input  wire [255:0] wr_ddr_data,

    output wire         wr_req,
    input  wire         wr_ack,
    output wire         wr_done,
    output wire         wr_busy,

    input  wire         app_rdy,
    output wire [2:0]   app_cmd,
    output wire         app_en,
    output wire [28:0]  app_addr, 

    input  wire         app_wdf_rdy,
    output wire [255:0] app_wdf_data,
    output wire         app_wdf_wren,
    output wire         app_wdf_end,
    output wire [31:0]  app_wdf_mask
);
//parameter define
parameter IDLE        = 3'b001;
parameter WR_REQ      = 3'b010;
parameter WRITE       = 3'b100;

parameter TOTAL_PIXEL = 1024*768 - 8;
parameter BURST_LEN   = 64-1;
//internal signal
reg  [2:0]  state;
reg  [9:0]  cnt_data;
wire        add_cnt_data;
wire        end_cnt_data;

reg  [9:0]  cnt_cmd;
wire        add_cnt_cmd;
wire        end_cnt_cmd;

reg         app_wdf_wren_r;
reg         app_en_r;
reg  [28:0] app_addr_r;

reg         wr_done_r;
reg         wr_req_r;

assign app_cmd      = 3'b000;
assign app_wdf_mask = 32'd0;
assign app_wdf_wren = app_wdf_wren_r;
assign app_en       = app_en_r;
assign app_addr     = app_addr_r;
assign app_wdf_data = wr_ddr_data;
assign wr_done      = wr_done_r;
assign wr_busy      = (state == WRITE);
assign wr_req       = wr_req_r;
assign app_wdf_end  = app_wdf_wren_r;

assign data_req = (app_wdf_wren_r & app_wdf_rdy);
//state machine
always @(posedge ui_clk) begin
    if (rst) state <= IDLE;
    else begin
        case (state)
            IDLE:begin
                if (wr_start) state <= WR_REQ;
                else state <= IDLE;
            end 
            WR_REQ:begin
                if (wr_ack) state <= WRITE;
                else state <= WR_REQ;
            end
            WRITE:begin
                if (end_cnt_cmd) state <= IDLE;
                else state <= WRITE;
            end
            default: state <= IDLE;
        endcase
    end
end
//app_wdf_wren_r
always @(posedge ui_clk) begin
    if (rst) begin
        app_wdf_wren_r <= 1'b0;
    end
    else if (end_cnt_data) begin
        app_wdf_wren_r <= 1'b0;
    end
    else if (state == WR_REQ && wr_ack == 1'b1) begin
        app_wdf_wren_r <= 1'b1;
    end
end
//cnt_data
always @(posedge ui_clk) begin
    if (rst) begin
        cnt_data <= 0;
    end
    else if (add_cnt_data) begin
        if (end_cnt_data) begin
            cnt_data <= 0;
        end
        else cnt_data <= cnt_data + 1'b1;
    end
end

assign add_cnt_data = data_req;
assign end_cnt_data = add_cnt_data && cnt_data == BURST_LEN;
//app_en_r
always @(posedge ui_clk) begin
    if (rst) begin
        app_en_r <= 1'b0;
    end
    else if (end_cnt_cmd) begin
        app_en_r <= 1'b0;
    end
    else if (app_wdf_wren_r == 1'b1) begin
        app_en_r <= 1'b1;
    end
end
//cnt_cmd
always @(posedge ui_clk) begin
    if (rst) begin
        cnt_cmd <= 0;
    end
    else if add_cnt_cmd) begin
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
//wr_done_r
always @(posedge ui_clk) begin
    if (rst) begin
        wr_done_r <= 1'b0;
    end
    else if (end_cnt_cmd) begin
        wr_done_r <= 1'b1;
    end
    else wr_done_r <= 1'b0;
end
//wr_req_r
always @(psoedge ui_clk) begin
    if (rst) begin
        wr_req_r <= 1'b0;
    end
    else if (wr_ack) begin
        wr_req_r <= 1'b0;
    end
    else if (state == IDLE && wr_start) begin
        wr_req_r <= 1'b1;
    end
end

endmodule //ddr_wr_ctrl