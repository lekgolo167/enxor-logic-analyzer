`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Trigger_Controller
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


module Trigger_Controller(
    input [7:0] data_in,
    input channel_select,
    input trigger_type,
    input enable,
    input rst,
    input clk,
    input slow_clk_posedge,
    output triggered,
    output event_pulse,
    output [7:0] data_out
    );

    Event_Detector ED (
        .clk(clk),
        .data_in(data_in),
        .shift(slow_clk_posedge),
        .event_pulse(),
        .data_out()
    );
    
    Rise_Fall_Detection RFD (
        .clk(clk),
        .trigger_type(trigger_type),
        .enable(enable),
        .sig_in(),
        .trigger_event()
    );
    
endmodule
