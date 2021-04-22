`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Timestamp_Counter
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


module Timestamp_Counter(
    input i_sys_clk,
    input i_enable,
    input i_incr,
    input i_event,
    output o_rollover,
    output reg [7:0] o_time
    );
    
    assign o_rollover = (& o_time) & i_incr;
    
    always @(posedge i_sys_clk) begin
        if(!i_enable) begin
            o_time <= 1;
        end
        else if(i_event) begin
            o_time <= 1;
        end
        else if(i_incr) begin
            o_time <= o_time + 1;
        end    
    end // End always    
     
endmodule
