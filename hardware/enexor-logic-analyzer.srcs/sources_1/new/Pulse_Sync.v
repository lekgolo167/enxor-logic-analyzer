`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Pulse_Sync
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


module Pulse_Sync #(parameter DATA_WIDTH = 8)(
    input i_sys_clk,
    input [DATA_WIDTH-1:0] i_async,
    output reg [DATA_WIDTH-1:0] o_sync
    );
    
    
    always @(posedge i_sys_clk) begin
        o_sync <= i_async;
    end // End always
    
endmodule
