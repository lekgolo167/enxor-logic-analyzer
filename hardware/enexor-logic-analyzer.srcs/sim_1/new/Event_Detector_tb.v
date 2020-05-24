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


module Event_Detector_tb;


    reg clk, shift;
    wire event_pulse;
    reg [11:0] count;
    
    Event_Detector ED(
        .i_sys_clk(clk),
        .i_data(count[11:4]),
        .i_shift(shift),
        .o_event_pulse(event_pulse)
        );
        
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        shift = 0;
        count = 0;
    end
    
    always @(posedge clk) begin
        count <= count + 1;
        if(count % 4 == 0) begin
            shift <= 1;
        end
        else begin
            shift <= 0;
        end

    end
    
    initial
        #200 $finish;
    
endmodule