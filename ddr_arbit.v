`timescale 1ns / 1ps
module ddr_arbit(
    input  wire ui_clk,
    input  wire rst,
    input  wire wr_req,
    output wire wr_ack,
    input  wire wr_done,

    input  wire rd_req,
    output wire rd_ack,
    input  wire rd_done
);
//parameter define
parameter IDLE  = 4'b0001;
parameter ARBIT = 4'b0010;
parameter WRITE = 4'b0100;
parameter READ  = 4'b1000;
//internal signal
reg       wr_ack_r;
reg       rd_ack_r;
reg [3:0] state;

assign wr_ack = wr_ack_r;
assign rd_ack = rd_ack_r;
//state machine
always @(posedge ui_clk) begin
    if (rst) begin
        state <= IDLE;
    end
    else begin
        case (state)
            IDLE:begin
                state <= ARBIT;
            end 
            ARBIT:begin
                if (wr_req) begin
                    state <= WRITE;
                end
                else if (!wr_req && rd_req) begin
                    state <= READ;
                end
            end
            WRITE:begin
                if (wr_done) begin
                    state <= ARBIT;
                end
                else state <= WRITE;
            end
            READ:begin
                if (rd_done) begin
                    state <= ARBIT;
                end
                else state <= READ;
            end
            default: state <= IDLE;
        endcase
    end
end
//wr_ack_r
always @(posedge ui_clk) begin
    if (rst) begin
        wr_ack_r <= 1'b0;
    end
    else if (state == ARBIT && wr_req) begin
        wr_ack_r <= 1'b1;
    end
    else wr_ack_r <= 1'b0;
end
//rd_ack_r
always @(posedge ui_clk) begin
    if (rst) begin
        rd_ack_r <= 1'b0;
    end
    else if (state == ARBIT && !wr_req && rd_req) begin
        rd_ack_r <= 1'b1;
    end
    else rd_ack_r <= 1'b0;
end

endmodule //ddr_arbit