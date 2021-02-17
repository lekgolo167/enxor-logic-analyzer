`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 06:18:58 PM
// Design Name: 
// Module Name: UART
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


module uart #(parameter CLKS_PER_BIT = 87)(
input i_sys_clk,
input i_Rx_Serial,
input i_Tx_DV,
input [7:0] i_Tx_Byte,
output o_Tx_Serial,
output o_Rx_DV,
output [7:0] o_Rx_Byte,
output o_Tx_Done
    );
    
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) URX (
        .i_sys_clk(i_sys_clk),
        .i_Rx_Serial(i_Rx_Serial),
        .o_Rx_DV(o_Rx_DV),
        .o_Rx_Byte(o_Rx_Byte)
    );
    
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) UTX (
        .i_sys_clk(i_sys_clk),
        .i_Tx_DV(i_Tx_DV),
        .i_Tx_Byte(i_Tx_Byte),
        .o_Tx_Serial(o_Tx_Serial),
        .o_Tx_Done(o_Tx_Done)  
    );
    
endmodule
