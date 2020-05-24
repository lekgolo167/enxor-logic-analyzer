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


module Rise_Fall_Detection (
    input i_sys_clk,
    input i_rst,
    input i_sig,
    input i_trigger_type,
    input i_enable,
    output o_trigger_pulse,
    output o_triggered_state
    );
    
    reg sig_dly, r_trigger_event;
    wire pe, ne, w_trigger_event;
    
    assign o_trigger_pulse = ((pe & i_trigger_type) | (ne & ~i_trigger_type)) & i_enable;
    assign o_triggered_state = o_trigger_pulse | r_trigger_event;
    
    always @(posedge i_sys_clk) begin
            sig_dly <= i_sig;
            
    end
    
    // Posedge detection
    assign pe = i_sig & ~sig_dly;
    // Negedge detection
    assign ne = ~i_sig & sig_dly;
    
    always @(posedge i_sys_clk, negedge i_rst) begin
        if (!i_rst) begin
            r_trigger_event <= 0;
        end
        else if (i_enable & o_trigger_pulse) begin
                r_trigger_event <= 1;
        end 
    end // End always
    
endmodule
