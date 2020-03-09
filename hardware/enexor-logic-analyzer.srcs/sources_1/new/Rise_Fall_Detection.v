`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Rise_Fall_Detection
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


module Rise_Fall_Detection(
    input clk,
    input rst,
    input sig_in,
    input trigger_type,
    input enable,
    output reg trigger_event
    );
    
    reg sig_dly;
    wire pe, ne;
    
    always @(posedge clk) begin
        sig_dly <= sig_in;
    end
    // Posedge detection
    assign pe = sig_in & ~sig_dly;
    // Negedge detection
    assign ne = ~sig_in & sig_dly;
    
    always @(posedge clk, negedge rst) begin
        if (!rst) begin
            trigger_event <= 0;
        end
        else if (enable) begin
            if (trigger_type) begin
                trigger_event <= pe;
            end
            else begin
                trigger_event <= ne;
            end
        end 
        else begin
            trigger_event <= 0;
        end
    end
    
endmodule
