`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 05/28/2020 06:18:58 PM
// Design Name: 
// Module Name: UART
// Project Name: Enxor Logic Analyzer
// Target Devices: 
// Tool Versions: 
// Description: 
// 
//      Copyright (C) 2021  Matthew Crump
//
// 		This program is free software: you can redistribute it and/or modify
// 		it under the terms of the GNU General Public License as published by
// 		the Free Software Foundation, either version 3 of the License, or
// 		(at your option) any later version.
//
// 		This program is distributed in the hope that it will be useful,
// 		but WITHOUT ANY WARRANTY; without even the implied warranty of
// 		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// 		GNU General Public License for more details.
//
// 		You should have received a copy of the GNU General Public License
// 		along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
