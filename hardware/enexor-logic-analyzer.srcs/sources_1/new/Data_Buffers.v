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


module Data_Buffers #(PACKET_WIDTH = 16, PRE_DEPTH = 256, POST_DEPTH = 1024)(
    input i_sys_clk,
    input i_rstn,
    input i_triggered,
    input i_data,
    input i_trig_statef,
    input i_post_trig_buff,
    input [11:0] i_r_addr,
    output [PACKET_WIDTH-1:0] o_rd_data,
    output o_done
);
    
    Pre_Trig_Buffer #(.ADDR_WIDTH($clog2(PRE_DEPTH)), .DATA_WIDTH(PACKET_WIDTH), .DEPTH(PRE_DEPTH)) PRTB (
    
    );
    
    Post_Trig_Buffer #(.ADDR_WIDTH($clog2(POST_DEPTH)), .DATA_WIDTH(PACKET_WIDTH), .DEPTH(POST_DEPTH)) PSTB (
    
    );
    
endmodule
