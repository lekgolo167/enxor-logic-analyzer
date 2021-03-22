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


module Logic_Analyzer_Top #(parameter DATA_WIDTH = 8, parameter PACKET_WIDTH = 16, parameter MEM_DEPTH = 8192)(
    input i_sys_clk,
    input i_rstn,
    input [DATA_WIDTH-1:0] i_raw_sig,
    input i_rx,
    output o_triggered_led,
    output o_enabled,
    output o_hold,
    output o_tx
);
    
    wire [DATA_WIDTH-1:0] w_channels;
    wire [PACKET_WIDTH-1:0] w_data;
    wire [$clog2(MEM_DEPTH)-1:0] w_precap_depth;
    wire [$clog2(DATA_WIDTH)-1:0] w_channel_select;
    wire [7:0] w_time, w_tx_byte, w_rx_byte;
    wire [15:0] w_scaler;
    wire w_sample_clk_posedge, w_triggered_state, w_rollover, w_event, w_trig_pulse, w_rstn, w_buffer_full, w_finished_read, w_trigger_type;
    wire w_r_ack, w_enable, w_start_read, w_t_rdy, w_tx_DV, w_rx_DV, w_tx_done, w_post_read, w_hold, w_prefilled;
    
    assign o_triggered_led = w_triggered_state;
    assign o_enabled = w_enable;
    assign o_hold = w_hold;
    
    Reset_Sync RST(
        .i_sys_clk(i_sys_clk),
        .i_rstn(i_rstn),
        .o_rstsync(w_rstn)
    );
    
    Pulse_Sync #(.DATA_WIDTH(DATA_WIDTH))PS (
        .i_sys_clk(i_sys_clk),
        .i_async(i_raw_sig),
        .o_sync(w_channels)
    );
    
    Clock_Divider CD (
        .i_sys_clk(i_sys_clk),
        .i_enable(w_enable),
        .i_scaler(w_scaler),
        .o_sample_clk_posedge(w_sample_clk_posedge)
    );
    
    Timestamp_Counter TSC (
        .i_sys_clk(i_sys_clk),
        .i_enable(w_enable),
        .i_incr(w_sample_clk_posedge),
        .i_event(w_event),
        .o_rollover(w_rollover),
        .o_time(w_time)    
    );
    
    Trigger_Controller #(.DATA_WIDTH(DATA_WIDTH)) TC (
        .i_sys_clk(i_sys_clk),
        .i_data(w_channels),
        .i_channel_select(w_channel_select),
        .i_trigger_type(w_trigger_type),
        .i_enable(w_enable),
        .i_sample_clk_posedge(w_sample_clk_posedge),
        .i_prefilled(w_prefilled),
        .i_hold(w_hold),
        .o_triggered_state(w_triggered_state),
        .o_event_pulse(w_event)
        );

    Data_Buffers_Programmable #(.PACKET_WIDTH(PACKET_WIDTH), .MEM_DEPTH(MEM_DEPTH)) DBS(
        .i_sys_clk(i_sys_clk),
        .i_rstn(w_rstn),
        .i_enable(w_enable),
        .i_stop(0),
        .i_precap_depth(w_precap_depth),
        .i_triggered_state(w_triggered_state),
        .i_event(w_event | w_rollover),
        .i_r_ack(w_r_ack),
        .i_start_read(w_start_read),
        .i_data({w_time, w_channels}),
        .o_prefilled(w_prefilled),
        .o_post_read(w_post_read),
        .o_buffer_full(w_buffer_full),
        .o_finished_read(w_finished_read),
        .o_data(w_data),
        .o_t_rdy(w_t_rdy)
    );
        
    FSM_Controller #(.DATA_WIDTH(DATA_WIDTH), .PACKET_WIDTH(PACKET_WIDTH), .MEM_DEPTH(MEM_DEPTH)) FSM (
        .i_sys_clk(i_sys_clk),
        .i_rstn(w_rstn),
        .i_triggered_state(w_triggered_state),
        .i_buffer_full(w_buffer_full),
        .i_finished_read(w_finished_read),
        .i_post_read(w_post_read),
        .i_t_rdy(w_t_rdy),
        .i_rx_DV(w_rx_DV),
        .i_tx_done(w_tx_done),
        .i_rx_byte(w_rx_byte),
        .i_data(w_data),
        .o_scaler(w_scaler),
        .o_precap_depth(w_precap_depth),
        .o_channel_select(w_channel_select),
        .o_trigger_type(w_trigger_type),
        .o_enable(w_enable),
        .o_hold(w_hold),
        .o_r_ack(w_r_ack),
        .o_start_read(w_start_read),
        .o_tx_DV(w_tx_DV),
        .o_tx_byte(w_tx_byte)
    );
    
    uart #(.CLKS_PER_BIT(868)) USB (
        .i_sys_clk(i_sys_clk),
        .i_Rx_Serial(i_rx),
        .i_Tx_DV(w_tx_DV),
        .i_Tx_Byte(w_tx_byte),
        .o_Tx_Serial(o_tx),
        .o_Rx_DV(w_rx_DV),
        .o_Rx_Byte(w_rx_byte),
        .o_Tx_Done(w_tx_done)
    );

endmodule
