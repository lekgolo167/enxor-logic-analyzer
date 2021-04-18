`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/30/2020 08:50:05 AM
// Design Name: 
// Module Name: Data_Width_Converter
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
    
    wire [2:0] packet_case = {i_post_read, i_buffer_full, i_triggered_state & ~i_start_read};
    reg [7:0] packet_header;
    wire [PACKET_WIDTH+8-1:0] data = {i_data, packet_header};
    reg [3:0] byte, r_state;
    
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
    
    assign o_tx_byte = ( byte == 0 )? data[7:0] : ( byte == 1 )? data[15:8] : ( byte == 2 )? data[23:16] : 8'b0;
    
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
                        o_tx_DV <= 0; // Move these two into the state WAIT?
                        o_r_ack <= 0;
                        byte <= 0;
                    end
                end
                TRIG: begin
                    if (i_buffer_full) begin // might change this to tx_active
                        o_tx_DV <= 1;
                        r_state <= FULL;
                    end
                    else if (i_tx_done) begin
                        o_tx_DV <= 0;
                    end
                end
                FULL: begin
                    if (i_start_read) begin // might change this to tx_active
                        o_tx_DV <= 1;
                        r_state <= SEND;
                    end
                    else if (i_tx_done)begin
                        o_tx_DV <= 0;
                    end
                end
                SEND: begin
                    if (i_tx_done) begin // might change this to tx_active
                        o_tx_DV <= 0;
                        r_state <= INCR;
                    end
                    else begin
                        o_tx_DV <= 1;
                    end
                end
                INCR: begin
                    if (byte == 2) begin // change this to a parameter
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
