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
    input [1:0]  i_trigger_type,
    input i_enable,
    input i_sample_clk_posedge,
    output reg o_triggered_state,
    output o_event_pulse
    );
    
    localparam FALLING_EDGE = 2'b00;
    localparam RISING_EDGE = 2'b01;
    localparam LEVEL_LOW = 2'b10;
    localparam LEVEL_HIGH = 2'b11;

    reg [DATA_WIDTH-1:0] r_last;
    reg r_trigger_event;
    wire pe, ne, w_edge_trigger, w_level_trigger;
    
    // Posedge detection
    assign pe = i_data[i_channel_select] & ~r_last[i_channel_select];
    // Negedge detection
    assign ne = ~i_data[i_channel_select] & r_last[i_channel_select];

    assign w_edge_trigger = (pe == 1'b1) || (ne == 1'b1);
    assign w_level_trigger = (i_data[i_channel_select] == 1'b1 && i_trigger_type == LEVEL_HIGH) || (i_data[i_channel_select] == 1'b0 && i_trigger_type == LEVEL_LOW);
    
    assign o_event_pulse = (r_last != i_data) & i_sample_clk_posedge;
    
    
    always @(posedge i_sys_clk) begin
        if (i_sample_clk_posedge || !i_enable) begin
            r_last <= i_data;
        end
    end // End always
    
    
    always @(posedge i_sys_clk) begin
        if (!i_enable) begin
            o_triggered_state <= 0;
        end
        else if (i_sample_clk_posedge == 1'b1) begin
            case (i_trigger_type)
                FALLING_EDGE, RISING_EDGE: begin
                    if (w_edge_trigger) begin
                        o_triggered_state <= 1;
                    end
                end
                LEVEL_LOW, LEVEL_HIGH: begin
                    o_triggered_state <= w_level_trigger;
                end 
            endcase
        end
    end // End always
    
endmodule