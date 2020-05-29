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

    reg clk, rst, enable, triggered, rd_en, events, rollover;
    reg [7:0] timer, channels, last;
    reg [11:0] count;
    
    wire done;
    wire [15:0] data;
    
    Data_Buffers #(.PACKET_WIDTH(16), .PRE_DEPTH(4), .POST_DEPTH(12)) DUT (
        .i_sys_clk(clk),
        .i_rstn(rst),
        .i_enable(enable),
        .i_triggered_state(triggered),
        .i_wr_en(events | rollover),
        .i_rd_en(rd_en),
        .i_data({timer, channels}),
        .o_done(done),
        .o_data(data)
    );
    
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        triggered = 0;
        rst = 0;
        enable =0;
        triggered = 0;
        rd_en = 0;
        count = 0;
        timer = 0;
        channels = 0;
        last = 0;
        events = 0;
        rollover = 0;
        #5 rst = 1;
        #5 enable = 1;
    end
    
    always @(posedge clk) begin
        last <= channels;
        channels <= count[11:4];
        count <= count + 1;
        if(count == 177) begin
            triggered <= 1;
        end
        
        if(&timer) begin
            rollover <= 1;
        end
        else begin
            rollover <= 0;
        end
        if(last != channels) begin
            events <= 1;
        end
        else begin
            events <= 0;
        end
        if(events) begin
            timer <= 0;
        end
        else if(clk) begin
            timer <= timer + 1;
        end
    end // End always
    
    initial
        #1550 $finish;

endmodule
