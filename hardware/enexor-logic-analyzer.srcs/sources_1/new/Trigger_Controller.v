`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Trigger_Controller
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


module Trigger_Controller #(parameter DATA_WIDTH = 8)(
    input i_sys_clk,
    input [DATA_WIDTH-1:0] i_data,
    input [$clog2(DATA_WIDTH)-1:0] i_channel_select,
    input i_trigger_type,
    input i_enable,
    input i_sample_clk_posedge,
    input i_trigger_delay_en,
    input [7:0] i_trigger_delay,
    output o_triggered_state,
    output o_event_pulse
    );
    
    reg [DATA_WIDTH-1:0] r_last;
    reg r_trigger_event;
    wire pe, ne, w_trigger_pulse;
    reg [7:0] trigger_delay_count;
    wire delayed_trigger_event;
    
    assign w_trigger_pulse = ((pe & i_trigger_type) | (ne & ~i_trigger_type)) & i_enable;
    assign o_triggered_state = i_trigger_delay_en ? delayed_trigger_event : r_trigger_event;
    assign o_event_pulse = (r_last != i_data) & i_sample_clk_posedge;
    
    always @(posedge i_sys_clk) begin
        if (i_sample_clk_posedge || !i_enable) begin
            r_last <= i_data;
        end
    end // End always
    
    // Posedge detection
    assign pe = i_data[i_channel_select] & ~r_last[i_channel_select];
    // Negedge detection
    assign ne = ~i_data[i_channel_select] & r_last[i_channel_select];
    
    always @(posedge i_sys_clk) begin
        if (!i_enable) begin
            r_trigger_event <= 0;
        end
        else if (i_enable & w_trigger_pulse & i_sample_clk_posedge) begin
            r_trigger_event <= 1;
        end
    end // End always
    
    // trigger delay if enabled
    assign delayed_trigger_event = (trigger_delay_count == i_trigger_delay);
    always @(posedge i_sys_clk) begin
        if (r_trigger_event) begin
            if (i_sample_clk_posedge) begin
                trigger_delay_count <= trigger_delay_count + 1;
            end
        end
        else begin
            trigger_delay_count <= 0;
        end
    end
    
endmodule
