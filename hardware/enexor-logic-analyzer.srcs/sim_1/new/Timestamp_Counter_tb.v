`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 05/23/2020 09:26:41 PM
// Design Name: 
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


module Timestamp_Counter_tb;

    reg clk, incr, _event, enable;
    wire w_rollover;
    wire [7:0] w_time;
    
    Timestamp_Counter tsc (
        .i_sys_clk(clk),
        .i_enable(enable),
        .i_event(_event),
        .i_incr(incr),
        .o_rollover(w_rollover),
        .o_time(w_time)
    );
    
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        enable = 0;
        incr = 0;
        _event = 0;
        #11 enable = 1;
    end
    
    always @(posedge clk) begin
        incr <= ~incr;
    end
    
    initial
        #2100 $finish;
        
endmodule
