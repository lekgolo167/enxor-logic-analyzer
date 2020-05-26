`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 02:12:42 PM
// Design Name: 
// Module Name: Data_Buffers
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Pre_Trig_Buffer #(ADDR_WIDTH = $clog2(256), PACKET_WIDTH = 16, DEPTH = 256) (
    input i_sys_clk,
    input i_rstn,
    input i_enable,
    input i_pre_trig_state,
    input i_event,
    input i_rd_adr,
    input [PACKET_WIDTH-1:0] i_data,
    output [PACKET_WIDTH-1:0] o_data
);
    wire w_wr_en;
    reg [ADDR_WIDTH-1:0] r_wr_adr, r_last;
    
    assign w_wr_en = i_pre_trig_state & i_enable & i_event;
    
    always @(posedge i_sys_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_wr_adr <= 0;
            r_last <= 0;
        end
        else if(w_wr_en) begin
            r_wr_adr <= r_wr_adr + 1;
            r_last <= r_wr_adr;
        end
    end // Endl always
    
    sram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(PACKET_WIDTH), .DEPTH(DEPTH)) sram_0 (
        .i_sys_clk(i_sys_clk),
        .i_wr_en(w_wr_en),
        .i_wr_adr(r_wr_adr),
        .i_rd_adr(i_rd_adr),
        .i_data(i_data),
        .o_data(o_data)
    );
    
endmodule