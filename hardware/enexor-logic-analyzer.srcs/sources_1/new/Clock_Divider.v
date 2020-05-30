`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:59:58 PM
// Design Name: 
// Module Name: Clock_Divider
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


module Clock_Divider(
    input i_sys_clk,
    input i_rstn,
    input [16:0] i_scaler, // CLK / scalar / 2 = sample rate
    output reg o_sample_clk_posedge
    );
    
    reg [16:0] r_count;
    
    always @(posedge i_sys_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_count <= 0;
        end
        else begin
            r_count <= r_count + 1;
            if (r_count == i_scaler) begin
                r_count <= 0;
                o_sample_clk_posedge <= 1;
            end
            else begin
                o_sample_clk_posedge <= 0;
            end
        end
    end // End always
    
    
endmodule
