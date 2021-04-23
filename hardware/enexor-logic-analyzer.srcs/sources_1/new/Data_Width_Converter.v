`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 12/30/2020 08:50:05 AM
// Design Name: 
// Module Name: Data_Width_Converter
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


module Data_Width_Converter #(parameter PACKET_WIDTH = 16) (
    input i_clk,
    input i_triggered_state,
    input i_post_read,
    input i_start_read,
    input i_buffer_full,
    input i_enable,
    input [PACKET_WIDTH-1:0] i_data,
    input i_t_rdy,
    input i_tx_done,
    output reg o_r_ack,
    output reg o_tx_DV,
    output [7:0] o_tx_byte
    );

    localparam NUM_OF_BYTES = (PACKET_WIDTH / 8) + 1;
    
    reg [$clog2(NUM_OF_BYTES)-1:0] byte;
    wire [2:0] packet_case = {i_post_read, i_buffer_full, i_triggered_state & ~i_start_read};
    reg [7:0] packet_header;
    wire [PACKET_WIDTH+8-1:0] data = {i_data, packet_header};
    reg [3:0] r_state;
    
    localparam IDLE = 3'b000;
    localparam TRIG = 3'b001;
    localparam FULL = 3'b010;
    localparam SEND = 3'b011;
    localparam INCR = 3'b100;
    localparam ACK = 3'b101;
    localparam WAIT = 3'b110;
    
    localparam PRE_BUFF = 8'hA1;
    localparam POST_BUFF = 8'hA3;
    localparam TRIGGERED = 8'hA7;
    localparam DONE = 8'hAF;
    
    always @(*) begin
        case (packet_case)
            3'b001:
                begin
                    packet_header = TRIGGERED;
                end
            3'b011:
                begin
                    packet_header = DONE;
                end
            3'b010:
                begin
                    packet_header = PRE_BUFF;
                end
            3'b110:
                begin
                    packet_header = POST_BUFF;
                end
            default:
                begin
                    packet_header = 8'hFF;
                end
        endcase
    end // END always
    
    Mux #(.NUM_INPUTS(NUM_OF_BYTES)) mux (
        .i_data(data),
        .i_sel(byte),
        .o_data(o_tx_byte)
    );
    
    always @(posedge i_clk) begin
        if (~i_enable) begin
            r_state <= IDLE;
        end
        else begin 
            case (r_state)
                IDLE: begin
                    if (i_triggered_state) begin
                        r_state <= TRIG;
                        o_tx_DV <= 1;
                    end
                    else begin
                        o_tx_DV <= 0;
                        o_r_ack <= 0;
                        byte <= 0;
                    end
                end
                TRIG: begin
                    if (i_buffer_full) begin
                        o_tx_DV <= 1;
                        r_state <= FULL;
                    end
                    else if (i_tx_done) begin
                        o_tx_DV <= 0;
                    end
                end
                FULL: begin
                    if (i_start_read) begin
                        o_tx_DV <= 1;
                        r_state <= SEND;
                    end
                    else if (i_tx_done)begin
                        o_tx_DV <= 0;
                    end
                end
                SEND: begin
                    if (i_tx_done) begin
                        o_tx_DV <= 0;
                        r_state <= INCR;
                    end
                    else begin
                        o_tx_DV <= 1;
                    end
                end
                INCR: begin
                    if (byte == (PACKET_WIDTH/8)) begin
                        o_r_ack <= 1;
                        r_state <= ACK;
                    end
                    else begin
                        byte <= byte + 1;
                        r_state <= SEND;
                    end
                end
                ACK: begin
                    if (!i_t_rdy) begin
                        o_r_ack <= 0;
                        r_state <= WAIT;
                    end
                end
                WAIT: begin
                    if (i_t_rdy) begin
                        r_state <= SEND;
                    end
                    else begin
                        o_tx_DV <= 0;
                        o_r_ack <= 0;
                        byte <= 0;
                    end
                end
            endcase
        end
    end // END always
    
endmodule
