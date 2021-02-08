`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2020 07:43:54 PM
// Design Name: 
// Module Name: Reset_Sync
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


module Reset_Sync(
	input i_sys_clk,
	input i_rstn,
	output reg o_rstsync
);
	reg R1;
	
	always @(posedge i_sys_clk or posedge i_rstn) begin
		if(i_rstn) begin
			R1 <= 0;
			o_rstsync <= 0;
		end
		else begin
			R1 <= 1;
			o_rstsync <= R1;
		end
	end
	
endmodule
