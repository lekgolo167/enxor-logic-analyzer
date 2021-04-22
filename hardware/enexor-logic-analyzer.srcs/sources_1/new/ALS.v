`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 04/15/2021 02:00:33 PM
// Design Name: 
// Module Name: ALS
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


module ALS(
    input clk,
    input MISO,
    input rst,
    output SCLK,
    output CS,
    output [7:0] led
    );
    
    parameter refresh_period = 75_000;
    
    wire d_rdy;
    wire [15:0] d;
    reg rd;
    
    reg [31:0] rd_count;
    
    simpleSPI SPI1(
        .clk(clk),
        .MISO(MISO),
        .rd(rd),
        .rst(rst),
        .SCLK(SCLK),
        .CS(CS),
        .d_rdy(d_rdy),
        .d(led)
    );
    
    assign led = d[12:5];
    
    initial begin 
        rd = 0;
        rd_count = 0;
    end
    
    always @(posedge SCLK) begin
        if ((d_rdy == 1) && (rd == 1)) begin
            rd <= 0;
        end
        // Read four times per second;
        if (rd_count > refresh_period) begin
            rd <= 1;
            rd_count <= 0;
        end
        else begin
            rd_count <= rd_count + 1;
        end
    end
     
endmodule