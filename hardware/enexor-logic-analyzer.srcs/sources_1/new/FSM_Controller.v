`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/09/2020 11:44:28 PM
// Design Name: 
// Module Name: FSM_Controller
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


module FSM_Controller #(parameter DATA_WIDTH = 8, parameter PACKET_WIDTH = 16)(
    input i_sys_clk,
    input i_buffer_full,
    input i_finished_read,
    input i_t_rdy,
    input i_rx_DV,
    input i_tx_active,
    input i_tx_done,
    input [7:0] i_rx_byte,
    input [PACKET_WIDTH-1:0] i_data,
    output reg [15:0] o_scaler,
    output reg [$clog2(DATA_WIDTH)-1:0] o_channel_select,
    output reg o_trigger_type,
    output reg o_enable,
    output reg o_r_ack,
    output reg o_start_read,
    output reg o_tx_DV,
    output reg [7:0] o_tx_byte
    );
    
    
endmodule
