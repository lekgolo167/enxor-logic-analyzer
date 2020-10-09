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
    output o_triggered_state,
    output o_event_pulse
    );
    
    reg [DATA_WIDTH-1:0] r_last;
    reg sig_dly, r_trigger_event;
    wire pe, ne, w_trigger_pulse;
    
    assign w_trigger_pulse = ((pe & i_trigger_type) | (ne & ~i_trigger_type)) & i_enable;
    assign o_triggered_state = (o_event_pulse & w_trigger_pulse) | r_trigger_event;
    assign o_event_pulse = (r_last != i_data)  & i_sample_clk_posedge;
    
    always @(posedge i_sys_clk) begin
        if (i_sample_clk_posedge) begin
            r_last <= i_data;
        end
    end // End always
    
    // Posedge detection
    assign pe = i_data[i_channel_select] & ~r_last[i_channel_select];
    // Negedge detection
    assign ne = ~i_data[i_channel_select] & r_last[i_channel_select];
    
    always @(posedge i_sys_clk, negedge i_rstn) begin
        if (!i_rstn | !i_enable) begin
            r_trigger_event <= 0;
        end
        else if (i_enable & w_trigger_pulse & i_sample_clk_posedge) begin
            r_trigger_event <= 1;
        end 
    end // End always
    
endmodule
