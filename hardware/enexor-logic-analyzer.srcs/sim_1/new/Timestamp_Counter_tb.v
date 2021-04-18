`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2020 09:26:41 PM
// Design Name: 
// Module Name: Timestamp_Counter_tb
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


module Timestamp_Counter_tb;

    reg clk, incr, _event, enable;
    wire w_rollover;
    wire [7:0] w_time;
    
    Timestamp_Counter tsc (
        .i_sys_clk(clk),
        .i_enable(enable),
        .i_event(_event),
        .i_incr(incr),
        .o_rollover(w_rollover),
        .o_time(w_time)
    );
    
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        enable = 0;
        incr = 0;
        _event = 0;
        #11 enable = 1;
    end
    
    always @(posedge clk) begin
        incr <= ~incr;
    end
    
    initial
        #2100 $finish;
        
endmodule
