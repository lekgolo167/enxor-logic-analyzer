`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 10/09/2020 11:44:28 PM
// Design Name: 
// Module Name: FSM_Controller
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


module FSM_Controller #(parameter DATA_WIDTH = 8, parameter PACKET_WIDTH = 16, parameter MEM_DEPTH = 16)(
    input i_sys_clk,
    input i_rstn,
    input i_triggered_state,
    input i_post_read,
    input i_buffer_full,
    input i_finished_read,
    input i_t_rdy,
    input i_rx_DV,
    input i_tx_done,
    input [7:0] i_rx_byte,
    input [PACKET_WIDTH-1:0] i_data,
    output reg [15:0] o_scaler,
    output reg [$clog2(MEM_DEPTH)-1:0] o_precap_depth,
    output reg [$clog2(DATA_WIDTH)-1:0] o_channel_select,
    output reg o_trigger_type,
    output reg o_enable,
    output o_r_ack,
    output reg o_start_read,
    output reg o_stop,
    output o_tx_DV,
    output [7:0] o_tx_byte
    );
    
    Data_Width_Converter #(.PACKET_WIDTH(PACKET_WIDTH)) DWC ( 
        .i_clk(i_sys_clk),
        .i_triggered_state(i_triggered_state),
        .i_start_read(o_start_read),
        .i_post_read(i_post_read),
        .i_buffer_full(i_buffer_full),
        .i_enable(o_enable),
        .i_data(i_data),
        .i_t_rdy(i_t_rdy),
        .i_tx_done(i_tx_done),
        .o_r_ack(o_r_ack),
        .o_tx_DV(o_tx_DV),
        .o_tx_byte(o_tx_byte)
    );
    
    localparam s_COMMAND =  2'b00;
    localparam s_VALUE =    2'b01;
    localparam s_SAVE =     2'b10;
    
    localparam SET_START_READ =     8'hF9;
    localparam SET_SCALER =         8'hFA;
    localparam SET_CHANNEL =        8'hFB;
    localparam SET_TRIG_TYPE =      8'hFC;
    localparam SET_ENABLE =         8'hFD;
    localparam SET_PRECAP_DEPTH =   8'hFE;
    localparam SET_STOP =           8'hFF;
    
    reg r_save, r_stored, r_start_read;
    reg [1:0] r_SM_cmd;
    reg [7:0] commandByte;
    reg [7:0] paramByte;
    
    always @(posedge i_sys_clk) begin
        if (!i_rstn) begin
            r_SM_cmd <= s_COMMAND;
        end
        else begin
        case (r_SM_cmd)
            s_COMMAND:
                begin
                    if(i_rx_DV) begin
                        commandByte <= i_rx_byte;
                        r_SM_cmd <= s_VALUE;
                    end
                end
            s_VALUE: 
                begin
                    if(i_rx_DV) begin
                        paramByte <= i_rx_byte;
                        r_SM_cmd <= s_SAVE;
                    end
                end
            s_SAVE:
                begin
                    r_save <= 1;
                    if (r_stored) begin
                        r_save <= 0;
                        r_SM_cmd <= s_COMMAND;
                    end
                end
        endcase
        end
    end
    
    always @(posedge i_sys_clk) begin
        if (!i_rstn) begin
            o_scaler <= 0;
            o_channel_select <= 0;
            o_trigger_type <= 0;
            o_enable <= 0;
            r_start_read <= 0;
            o_stop <= 0;
        end 
        else begin
            r_stored <= 0;
            if (r_save && !r_stored) begin
                r_stored <= 1;
                case (commandByte)
                    SET_START_READ: begin
                        r_start_read <= paramByte[0];
                    end
                    SET_SCALER:
                        begin
                            o_scaler <= {o_scaler[7:0], paramByte};
                        end
                    SET_PRECAP_DEPTH:
                        begin
                            o_precap_depth <= {o_precap_depth[7:0], paramByte};
                        end
                    SET_CHANNEL: 
                        begin
                            o_channel_select <= paramByte[$clog2(DATA_WIDTH)-1:0];
                        end
                    SET_TRIG_TYPE:
                        begin
                            o_trigger_type <= paramByte[0];
                        end
                    SET_ENABLE:
                        begin
                            o_enable <= paramByte[0];
                        end
                    SET_STOP:
                        begin
                            o_stop <= paramByte[0];
                        end
                endcase
            end
        end
    end

    always @(posedge i_sys_clk) begin
        o_start_read <= r_start_read & ~i_finished_read;
    end
endmodule
