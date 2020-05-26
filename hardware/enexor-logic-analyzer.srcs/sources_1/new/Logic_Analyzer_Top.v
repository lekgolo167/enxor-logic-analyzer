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

module Logic_Analyzer_Top(
    input i_sys_clk,
    input [DATA_WIDTH:0] i_raw_sig,
    input i_rx,
    output o_triggered_led,
    output o_tx
);
    
    wire [DATA_WIDTH-1:0] w_channels;
    wire w_sample_clk_posedge;
    
    Pulse_Sync #(.DATA_WIDTH(DATA_WIDTH))PS (
        .i_sys_clk(i_sys_clk),
        .i_async(i_raw_sig),
        .o_sync(w_channels)
    );
    
    Clock_Divider CD (
        .i_sys_clk(i_sys_clk),
        .i_rstn(),
        .i_scalar(),
        .o_sample_clk_posedge(w_sample_clk_posedge)
    );
    
    Timestamp_Counter TSC (
        .i_sys_clk(i_sys_clk),
        .i_rstn(),
        .i_incr(w_sample_clk_posedge),
        .o_rollover(),
        .o_time()    
    );
    
    Trigger_Controller #(.DATA_WIDTH(DATA_WIDTH)) TC (
        .i_sys_clk(i_sys_clk),
        .i_rstn(),
        .i_data(w_channels),
        .i_channel_select(),
        .i_trigger_type(),
        .i_enable(),
        .i_sample_clk_posedge(w_sample_clk_posedge),
        .o_trigger_pulse(),
        .o_triggered_state(),
        .o_event_pulse(),
        .o_data()
        );
        
    Data_Buffers DBS (
        .i_sys_clk(),
        .i_rstn(),
        .i_triggered(),
        .i_data(),
        .i_pre_trig_buff(),
        .i_post_trig_buff(),
        .i_r_addr(),
        .i_r_enable(),
        .o_r_data(),
        .o_done()
    );
    
endmodule
