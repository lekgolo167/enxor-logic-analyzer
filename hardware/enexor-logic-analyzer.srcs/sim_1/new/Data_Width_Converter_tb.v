`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/31/2020 01:21:37 AM
// Design Name: 
// Module Name: Data_Width_Converter_tb
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


module Data_Width_Converter_tb;

    reg [11:0] count;
    reg clk, rst, enable, start_read;
    wire [7:0] w_time, w_channels, tx_byte;
    
    
    wire w_sample_clk_posedge, w_rollover, w_triggered_state, w_event, finished_read,r_ack, t_rdy, buffer_full, tx_DV, tx_active, tx_serial, tx_done, post_read;
    wire [15:0] data;
    
    Pulse_Sync #(.DATA_WIDTH(8))PS (
        .i_sys_clk(clk),
        .i_async(count[11:4]),
        .o_sync(w_channels)
    );
    
    Clock_Divider CD (
        .i_sys_clk(clk),
        .i_enable(enable),
        .i_scaler(5),
        .o_sample_clk_posedge(w_sample_clk_posedge)
    );
    
    Timestamp_Counter TSC (
        .i_sys_clk(clk),
        .i_enable(enable),
        .i_incr(w_sample_clk_posedge),
        .i_event(w_event),
        .o_rollover(w_rollover),
        .o_time(w_time)    
    );
    
    Trigger_Controller #(.DATA_WIDTH(8)) TC (
        .i_sys_clk(clk),
        .i_data(w_channels),
        .i_channel_select(4),
        .i_trigger_type(1),
        .i_enable(enable),
        .i_sample_clk_posedge(w_sample_clk_posedge),
        .o_triggered_state(w_triggered_state),
        .o_event_pulse(w_event)
        );
        
    Data_Buffers #(.PACKET_WIDTH(16), .PRE_DEPTH(4), .POST_DEPTH(12)) DBS (
        .i_sys_clk(clk),
        .i_rstn(rst),
        .i_triggered_state(w_triggered_state),
        .i_event(w_event | w_rollover),
        .i_r_ack(r_ack),
        .i_start_read(start_read),
        .i_data({w_time, w_channels}),
        .o_post_read(post_read),
        .o_buffer_full(buffer_full),
        .o_finished_read(finished_read),
        .o_data(data),
        .o_t_rdy(t_rdy)
    );
    
    uart_tx #(.CLKS_PER_BIT(5)) tx (
        .i_sys_clk(clk),
        .i_Tx_DV(tx_DV),
        .i_Tx_Byte(tx_byte),
        .o_Tx_Serial(tx_serial),
        .o_Tx_Done(tx_done)
    );
    
    Data_Width_Converter #(.PACKET_WIDTH(16)) DUT (
        .i_clk(clk),
        .i_triggered_state(w_triggered_state),
        .i_post_read(post_read),
        .i_start_read(start_read),
        .i_buffer_full(buffer_full),
        .i_enable(enable),
        .i_data(data),
        .i_t_rdy(t_rdy),
        .i_tx_done(tx_done),
        .o_r_ack(r_ack),
        .o_tx_DV(tx_DV),
        .o_tx_byte(tx_byte)
    );
    
    wire [2:0] state = DUT.r_state;
    wire [7:0] packet_header = DUT.packet_header;
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        rst = 0;
        enable =0;
        count = 0;
        start_read = 0;
        #50 rst = 1;
        #15 enable = 1;
    end
    
    always @(posedge clk) begin
          
        if (finished_read) begin
            #250 start_read <= 0;
            #25 enable <= 0;
            #100 $finish;     
        end
        else if(buffer_full && !start_read) begin
            #500 start_read <= 1;
        end
    end // End always

    always @(posedge clk) begin
        count <= count + 1;
    end
    
endmodule
