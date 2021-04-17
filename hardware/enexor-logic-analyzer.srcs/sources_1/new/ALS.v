`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2021 02:00:33 PM
// Design Name: 
// Module Name: ALS
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


module ALS(
    input clk,
    input MISO,
    input rst,
    output SCLK,
    output CS,
    output [7:0] led
    );
    
    parameter refresh_period = 75_000;
    
    wire d_rdy;
    wire [15:0] d;
    reg rd;
    
    reg [31:0] rd_count;
    
    simpleSPI SPI1(
        .clk(clk),
        .MISO(MISO),
        .rd(rd),
        .rst(rst),
        .SCLK(SCLK),
        .CS(CS),
        .d_rdy(d_rdy),
        .d(led)
    );
    
    assign led = d[12:5];
    
    initial begin 
        rd = 0;
        rd_count = 0;
    end
    
    always @(posedge SCLK) begin
        if ((d_rdy == 1) && (rd == 1)) begin
            rd <= 0;
        end
        // Read four times per second;
        if (rd_count > refresh_period) begin
            rd <= 1;
            rd_count <= 0;
        end
        else begin
            rd_count <= rd_count + 1;
        end
    end
     
endmodule