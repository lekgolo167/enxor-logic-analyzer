`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Clock_Divider
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


module Clock_Divider(
    input i_sys_clk,
    input i_enable,
    input [15:0] i_scaler, // CLK / scalar / 2 = sample rate
    output reg o_sample_clk_posedge
    );
    
    reg [15:0] r_count;

    always @(posedge i_sys_clk) begin
        if(!i_enable) begin
            r_count <= 0;
            o_sample_clk_posedge <= 0;
        end
        else if (r_count >= i_scaler) begin
            r_count <= 0;
            o_sample_clk_posedge <= 1;
        end
        else begin
            r_count <= r_count + 1;
            o_sample_clk_posedge <= 0;
        end
    end // End always    
    
endmodule
