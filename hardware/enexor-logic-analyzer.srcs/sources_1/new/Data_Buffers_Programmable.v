`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Matthew Crump
// 
// Create Date: 03/02/2021 11:07:47 AM
// Design Name: 
// Module Name: Data_Buffers_Programmable
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


module Data_Buffers_Programmable #(parameter PACKET_WIDTH = 16, MEM_DEPTH = 16)(
    input i_sys_clk,
    input i_rstn,
    input i_enable,
    input i_stop,
    input [$clog2(MEM_DEPTH)-1:0] i_precap_depth,
    input i_triggered_state,
    input i_event,
    input i_r_ack,
    input i_start_read,
    input [PACKET_WIDTH-1:0] i_data,
    output reg o_prefilled,
    output reg o_post_read,
    output reg o_buffer_full,
    output reg o_finished_read,
    output [PACKET_WIDTH-1:0] o_data,
    output reg o_t_rdy
);

    localparam ADDR_WIDTH = $clog2(MEM_DEPTH);

    localparam s_INIT = 3'b000;
    localparam s_PRE_FILL = 3'b001;
    localparam s_PRE_CAPTURE = 3'b010;
    localparam s_POST_CAPTURE = 3'b100;
    localparam s_WAIT = 3'b111;
    localparam s_READ_PRE = 3'b001;
    localparam s_READ_POST = 3'b010;
    localparam s_WAIT_ACK = 3'b100;

    reg r_wr_en;
    reg [2:0] r_wr_state, r_rd_state, r_prev_state;
    reg [ADDR_WIDTH-1:0] r_end_ptr, r_triggered_mark_ptr, r_wr_adr;
    reg [ADDR_WIDTH-1:0] r_rd_adr;
    
    // writting buffer state machine
    always @(posedge i_sys_clk) begin
        if(!i_rstn) begin
            r_wr_state <= s_INIT;
        end
        else 
        begin
            case(r_wr_state)
                
                s_INIT :
                    begin
                        // initialize write signals
                        r_wr_en <= 0;
                        r_end_ptr <= 0;
                        r_wr_adr <= 0;
                        o_buffer_full <= 0;
                        o_prefilled <= 0;
                        if (i_enable) begin // wait here until the logic analyzer is enabled then enable write
                            r_wr_en <= 1;
                            r_wr_state <= s_PRE_FILL;
                        end
                    end
                
                s_PRE_FILL :
                    begin
                        r_wr_en <= 1;
                        if (i_event) begin
                            r_wr_adr <= r_wr_adr + 1;
                            // mark last written to precapture address
                            r_triggered_mark_ptr <= r_wr_adr; 
                        end

                        if (i_stop) begin
                            r_wr_state <= s_INIT;
                        end
                        // trigger event happened, precapture buffer is smaller than programmed size
                        else if (i_triggered_state) begin 
                            r_wr_state <= s_POST_CAPTURE;
                        end
                        // precapture buffer has grown to max size
                        else if (r_wr_adr == i_precap_depth) begin
                            o_prefilled <= 1;
                            r_wr_state <= s_PRE_CAPTURE;
                        end
                    end

                s_PRE_CAPTURE :
                    begin
                        if (i_event) begin
                            // circular buffer, constantly overwritten until trigger event
                            r_end_ptr <= r_end_ptr + 1;
                            r_wr_adr <= r_wr_adr + 1;
                            // mark last written precapture address
                            r_triggered_mark_ptr <= r_wr_adr;
                        end
                        if (i_stop) begin
                            r_wr_state <= s_INIT;
                        end
                        else if (i_triggered_state) begin
                            r_wr_state <= s_POST_CAPTURE;
                        end
                    end

                s_POST_CAPTURE:
                    begin
                        // fill buffer until write address wraps back around to first location written to
                        if ((r_wr_adr == r_end_ptr) | i_stop) begin
                            r_wr_state <= s_WAIT;
                            o_buffer_full <= 1;
                            r_wr_en <= 0;
                        end
                        else if (i_event) begin
                            r_wr_adr <= r_wr_adr + 1;
                        end
                    end

                s_WAIT:
                    begin
                        if (!i_enable) begin
                            r_wr_state <= s_INIT;
                        end
                    end

                default :
                    r_wr_state <= s_INIT;
            endcase    
        end
    end // End always
    

    // reading buffer state machine
    always @(posedge i_sys_clk) begin
        if(!i_rstn) begin
            r_rd_state <= s_INIT;
            r_prev_state <= s_WAIT_ACK;
        end
        else begin
            case(r_rd_state)
                s_INIT :
                    begin
                        if(i_start_read) begin
                            o_t_rdy <= 1;
                            r_rd_state <= s_READ_PRE;
                        end
                        // start reading from the oldest memory location
                        r_rd_adr <= r_end_ptr;
                        o_t_rdy <= 0;
                        o_post_read <= 0;
                        o_finished_read <= 0;
                    end

                s_READ_PRE:
                    begin
                        // signal that data is valid
                        o_t_rdy <= 1;
                        
                        // once read address = last
                        if(r_rd_adr == r_triggered_mark_ptr) begin
                            o_t_rdy <= 0;
                            r_rd_state <= s_WAIT_ACK;
                            r_prev_state <= s_READ_POST;
                        end
                        // wait for ack then move to next memory location
                        else if (i_r_ack) begin
                            o_t_rdy <= 0;
                            r_prev_state <= r_rd_state;
                            r_rd_state <= s_WAIT_ACK;
                            r_rd_adr <= r_rd_adr + 1;
                        end
                    end

                s_READ_POST:
                    begin
                        o_t_rdy <= 1;
                        
                        // once read address has reach last written location, done reading
                        if(r_rd_adr == r_wr_adr) begin
                            o_t_rdy <= 0;
                            r_rd_state <= s_WAIT_ACK;
                            r_prev_state <= s_WAIT;
                            o_finished_read <= 1;
                        end
                        // wait for ack then move to next memory location
                        else if (i_r_ack) begin
                            o_post_read <= 1;
                            o_t_rdy <= 0;
                            r_prev_state <= r_rd_state;
                            r_rd_state <= s_WAIT_ACK;
                            r_rd_adr <= r_rd_adr + 1;
                        end
                    end
                    
                s_WAIT_ACK:
                    begin
                        // wair for r_ack to deassert
                        if (!i_r_ack) begin
                            r_rd_state <= r_prev_state;
                        end
                    end
                
                s_WAIT:
                    begin
                        if (!i_enable) begin
                            r_rd_state <= s_INIT;
                        end
                    end

                default :
                    r_rd_state <= s_INIT;

            endcase
            
        end
    end // End always
    
    sram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(PACKET_WIDTH), .DEPTH(MEM_DEPTH)) sram_0 (
        .i_sys_clk(i_sys_clk),
        .i_wr_en(r_wr_en & i_event),
        .i_wr_adr(r_wr_adr),
        .i_rd_adr(r_rd_adr),
        .i_data(i_data),
        .o_data(o_data)
    );
    
endmodule
