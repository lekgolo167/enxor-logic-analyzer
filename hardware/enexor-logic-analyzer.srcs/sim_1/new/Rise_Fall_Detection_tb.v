`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/08/2020 12:05:08 PM
// Design Name: 
// Module Name: Rise_Fall_Detection_tb
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


module Rise_Fall_Detection_tb;

    reg clk, rst, enable, trig_type;
    wire trig_out;
    reg [5:0] count;
    
    Rise_Fall_Detection RFD(
        .i_sys_clk(clk),
        .i_rst(rst),
        .i_sig(count[2]),
        .i_trigger_type(trig_type),
        .i_enable(enable),
        .o_trigger_event(trig_out)
        );
        
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        rst = 0;
        enable = 0;
        trig_type = 0;
        count = 0;
        
        #10 rst = 1;
        #6 enable = 1;
    end
    
    always @(posedge clk) begin
        count <= count + 1;
        if(count % 25 == 0) begin
            rst <= 0;
            #16 rst <= 1;
        end
        if(count == 31)
            #64 trig_type = ~trig_type;
        else if(count == 63)
            enable <= ~enable;
    end
    
    initial
        #512 $finish;
    
endmodule
