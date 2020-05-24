`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2020 12:55:41 AM
// Design Name: 
// Module Name: Trigger_Controller_tb
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


module Trigger_Controller_tb;

    parameter DATA_WIDTH = 8;
    
    reg clk, sample_clk_posedge, rst, enable, trig_type;
    reg [2:0] channel_select;
    reg [11:0] count;
    
    wire w_triggered_state, w_trigger_pulse, w_event_pulse;
    
    Trigger_Controller #(.DATA_WIDTH(DATA_WIDTH)) DUT (
        .i_data(count[11:4]),
        .i_channel_select(channel_select),
        .i_trigger_type(trig_type),
        .i_enable(enable),
        .i_rstn(rst),
        .i_sys_clk(clk),
        .i_sample_clk_posedge(sample_clk_posedge),
        .o_trigger_pulse(w_trigger_pulse),
        .o_triggered_state(w_triggered_state),
        .o_event_pulse(w_event_pulse)
    );
    
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        sample_clk_posedge = 0;
        rst = 0;
        enable =0;
        trig_type = 1;
        channel_select = 2;
        count = 0;
        #5 rst = 1;
        #5 enable = 1;
    end
    
    always @(posedge clk) begin
        count <= count + 1;
        if(count % 3 == 0) begin
            sample_clk_posedge <= 1;
        end
        else begin
            sample_clk_posedge <= 0;
        end
    end // End always
    
    initial
        #550 $finish;
        
        
endmodule
