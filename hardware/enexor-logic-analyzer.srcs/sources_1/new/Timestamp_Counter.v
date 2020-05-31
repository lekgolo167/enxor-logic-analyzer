`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Timestamp_Counter
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


module Timestamp_Counter(
    input i_sys_clk,
    input i_rstn,
    input i_incr,
    input i_event,
    output o_rollover,
    output reg [7:0] o_time
    );
    
    assign o_rollover = (& o_time) & i_incr;
    
    always @(posedge i_sys_clk or negedge i_rstn) begin
        if(!i_rstn) begin
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
