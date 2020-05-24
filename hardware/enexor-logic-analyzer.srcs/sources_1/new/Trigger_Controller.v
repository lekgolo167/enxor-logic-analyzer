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


module Trigger_Controller #(parameter DATA_WIDTH = 8)(
    input i_sys_clk,
    input i_rstn,
    input [DATA_WIDTH-1:0] i_data,
    input [2:0] i_channel_select,
    input i_trigger_type,
    input i_enable,
    input i_sample_clk_posedge,
    output o_trigger_pulse,
    output o_triggered_state,
    output o_event_pulse
    );
    
    Event_Detector ED (
        .i_sys_clk(i_sys_clk),
        .i_data(i_data),
        .i_shift(i_sample_clk_posedge),
        .o_event_pulse(o_event_pulse)
    );
    
    Rise_Fall_Detection RFD (
        .i_sys_clk(i_sys_clk),
        .i_rst(i_rstn),
        .i_sig(i_data[i_channel_select]),
        .i_trigger_type(i_trigger_type),
        .i_enable(i_enable),
        .o_trigger_pulse(o_trigger_pulse),
        .o_triggered_state(o_triggered_state)
    );
    
endmodule
