`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/25/2020 03:08:30 PM
// Design Name: 
// Module Name: sram
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


module sram #(parameter ADDR_WIDTH = 8, DATA_WIDTH = 8, DEPTH = 256)(
    input i_sys_clk,
    input [ADDR_WIDTH:0] i_wr_adr,
    input [ADDR_WIDTH:0] i_rd_adr,
    input i_wr_en,
    input [DATA_WIDTH-1:0] i_data,
    output reg [DATA_WIDTH-1:0] o_data
    );
    
    reg [DATA_WIDTH-1:0] memory_array [0:DEPTH-1]; 

    always @(posedge i_sys_clk) begin
        if(i_wr_en) begin
            memory_array[i_wr_adr] <= i_data;
        end
        o_data <= memory_array[i_rd_adr];
    end // End always
    
endmodule
