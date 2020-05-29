`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:28:46 PM
// Design Name: 
// Module Name: Logic_Analyzer_Top
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
parameter DATA_WIDTH = 8;
parameter PACKET_WIDTH = 16;
parameter PRE_DEPTH = 1024;
parameter POST_DEPTH = 7168;

module Logic_Analyzer_Top(
    input i_sys_clk,
    input i_rstn,
    input [DATA_WIDTH-1:0] i_raw_sig,
    input i_rx,
    output o_triggered_led,
    output o_tx
);
    
    wire [DATA_WIDTH-1:0] w_channels, w_time;
    wire w_sample_clk_posedge, w_triggered_state, w_rollover, w_event, w_trig_pulse;
    
    Pulse_Sync #(.DATA_WIDTH(DATA_WIDTH))PS (
        .i_sys_clk(i_sys_clk),
        .i_async(i_raw_sig),
        .o_sync(w_channels)
    );
    
    Clock_Divider CD (
        .i_sys_clk(i_sys_clk),
        .i_rstn(i_rstn),
        .i_scaler(),
        .o_sample_clk_posedge(w_sample_clk_posedge)
    );
    
    Timestamp_Counter TSC (
        .i_sys_clk(i_sys_clk),
        .i_rstn(i_rstn),
        .i_incr(w_sample_clk_posedge),
        .o_rollover(w_rollover),
        .o_time(w_time)    
    );
    
    Trigger_Controller #(.DATA_WIDTH(DATA_WIDTH)) TC (
        .i_sys_clk(i_sys_clk),
        .i_rstn(i_rstn),
        .i_data(w_channels),
        .i_channel_select(),
        .i_trigger_type(),
        .i_enable(),
        .i_sample_clk_posedge(w_sample_clk_posedge),
        .o_trigger_pulse(w_trig_pulse),
        .o_triggered_state(w_triggered_state),
        .o_event_pulse(w_event)
        );
        
    Data_Buffers #(.PACKET_WIDTH(PACKET_WIDTH), .PRE_DEPTH(PRE_DEPTH), .POST_DEPTH(POST_DEPTH)) DBS(
        .i_sys_clk(i_sys_clk),
        .i_rstn(i_rstn),
        .i_enable(),
        .i_triggered_state(w_triggered_state | w_trig_pulse),
        .i_data({w_time, w_channels}),
        .i_wr_en(w_event | w_rollover),
        .i_rd_en(),
        .o_data(),
        .o_done()
    );
    
    uart #(.CLKS_PER_BIT(868)) USB (
        .i_sys_clk(),
        .i_Rx_Serial(),
        .i_Tx_DV(),
        .i_Tx_Byte(),
        .o_Tx_Serial(),
        .o_Rx_DV(),
        .o_Rx_Byte(),
        .o_Tx_Active(),
        .o_Tx_Done()
    );
    
endmodule
