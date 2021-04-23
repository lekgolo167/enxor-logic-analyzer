`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2021 03:10:00 PM
// Design Name: 
// Module Name: Mux
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


module Mux #(parameter WIDTH = 8, NUM_INPUTS  = 16)(
  input [NUM_INPUTS-1:0] [WIDTH-1:0] i_data,
  input [$clog2(NUM_INPUTS)-1:0] i_sel,
  output [WIDTH -1:0] o_data
);

  assign o_data = i_data >> ( i_sel * WIDTH );
  
endmodule
