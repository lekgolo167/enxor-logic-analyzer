`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Event_Detector
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


module Event_Detector #(parameter DATA_WIDTH = 8)(
    input i_sys_clk,
    input [DATA_WIDTH-1:0] i_data,
    input i_shift,
    output o_event_pulse
    );
    
    reg [DATA_WIDTH-1:0] r_last;
   
    assign o_event_pulse = (r_last != i_data)  & i_shift;
    
    always @(posedge i_sys_clk) begin
        if (i_shift) begin
            r_last <= i_data;
        end
    end // End always
    
endmodule
