`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2020 06:48:06 PM
// Design Name: 
// Module Name: Data_Buffer_tb
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


module Data_Buffer_tb;

    reg clk, rst, enable, rd_en;
    wire [7:0] w_time, w_channels;
    reg [11:0] count;
    
    wire done, w_sample_clk_posedge, w_rollover, w_triggered_state, w_event;
    wire [15:0] data;
    
    Pulse_Sync #(.DATA_WIDTH(8))PS (
        .i_sys_clk(clk),
        //.i_shift(w_sample_clk_posedge),
        .i_async(count[11:4]),
        .o_sync(w_channels)
    );
    
    Clock_Divider CD (
        .i_sys_clk(clk),
        .i_rstn(rst),
        .i_scaler(5),
        .o_sample_clk_posedge(w_sample_clk_posedge)
    );
    
    Timestamp_Counter TSC (
        .i_sys_clk(clk),
        .i_rstn(rst),
        .i_incr(w_sample_clk_posedge),
        .i_event(w_event),
        .o_rollover(w_rollover),
        .o_time(w_time)    
    );
    
    Trigger_Controller #(.DATA_WIDTH(8)) TC (
        .i_sys_clk(clk),
        .i_rstn(rst),
        .i_data(w_channels),
        .i_channel_select(4),
        .i_trigger_type(1),
        .i_enable(enable),
        .i_sample_clk_posedge(w_sample_clk_posedge),
        .o_triggered_state(w_triggered_state),
        .o_event_pulse(w_event)
        );
        
    Data_Buffers #(.PACKET_WIDTH(16), .PRE_DEPTH(4), .POST_DEPTH(12)) DUT (
        .i_sys_clk(clk),
        .i_rstn(rst),
        .i_enable(enable),
        .i_triggered_state(w_triggered_state),
        .i_wr_en(w_event | w_rollover),
        .i_rd_en(rd_en),
        .i_data({w_time, w_channels}),
        .o_done(done),
        .o_data(data)
    );
    
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        rst = 0;
        enable =0;
        rd_en = 0;
        count = 0;
        #50 rst = 1;
        #15 enable = 1;
    end
    
    always @(posedge clk) begin
        count <= count + 1;
        if(done) begin
            enable <= 0;
            #100 rd_en <= 1;
        end
    end // End always
    
    initial
        #3000 $finish;

endmodule
