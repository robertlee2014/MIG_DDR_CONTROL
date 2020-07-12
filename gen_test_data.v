`timescale 1ns / 1ps
module gen_test_data(
    input  wire         ui_clk,
    input  wire         rst,
    input  wire         ddr_busy,

    output wire         wr_start,
    input  wire         data_req,
    output wire [255:0] wr_ddr_data,
    input  wire         wr_done,

    output wire         rd_start,
    input  wire         rd_data_vld,
    input  wire [255:0] rd_ddr_data,
    input  wire         rd_done,

    output wire         error
);
//parameter define
parameter IDLE    = 4'b0001;
parameter ARBIT   = 4'b0010;
parameter WRITE   = 4'b0100;
parameter READ    = 4'b1000;

parameter CNT_MAX = 64-1;
//internal signal
reg [3:0] state;
reg [7:0] cnt_data;
reg       wr_start_r;
reg       rd_start_r;
reg       error_r;
reg       wr_rd_flag;

assign wr_ddr_data = (wr_rd_flag)?{32{cnt_data}}:256'd0;
assign wr_start    = wr_start_r;
assign rd_start    = rd_start_r;
assign error       = error_r;
//state machine
always @(posedge ui_clk)begin
    if(rst == 1'b1)begin
        state <= IDLE;
    end
    else begin
        case(state)
            IDLE:begin
                state <= ARBIT;
            end
            ARBIT:begin
                if(wr_start_r)
                    state <= WRITE;
                else if(rd_start_r)
                    state <= READ;
            end
            WRITE:begin
                if(wr_done)
                    state <= ARBIT;
                else
                    state <= WRITE;
            end
            READ:begin
                if(rd_done)
                    state <= ARBIT;
                else
                    state <= READ;
            end
            default:begin
                state <= IDLE;
            end
        endcase
    end
end
//wr_rd_flag
always @(posedge ui_clk)begin
    if(rst)begin
        wr_rd_flag <= 1'b0;
    end
    else if(wr_done)begin
        wr_rd_flag <= 1'b1;
    end
    else if(rd_done)begin
        wr_rd_flag <= 1'b0;
    end
end
//wr_start_r,rd_start_r
always @(posedge ui_clk)begin
    if(rst)begin
        wr_start_r <= 1'b0;
        rd_start_r <= 1'b0;
    end
    else if(state==ARBIT && !ddr_busy && !wr_rd_flag)begin
        wr_start_r <= 1'b1;
    end
    else if(state==ARBIT && !ddr_busy && wr_rd_flag)begin
        rd_start_r <= 1'b1;
    end
    else begin
        rd_start_r <= 1'b0;
        wr_start_r <= 1'b0;
    end
end
//cnt_data
always @(posedge ui_clk)begin
    if(rst)begin
        cnt_data <= 'd0;
    end
    else if(data_req)begin
        if(cnt_data==CNT_MAX)
            cnt_data <= 'd0;
        else 
            cnt_data <= cnt_data + 1'b1;
    end
    else if(rd_data_vld)begin
        if(cnt_data==CNT_MAX)
            cnt_data <= 'd0;
        else 
            cnt_data <= cnt_data + 1'b1;
    end
end
//error
always @(posedge ui_clk)begin
    if(rst)begin
        error_r <= 1'b0;
    end
    else if(rd_data_vld && (rd_ddr_data !={32{cnt_data}}))begin
            error_r <= 1'b1;
    end
end

endmodule //gen_test_data