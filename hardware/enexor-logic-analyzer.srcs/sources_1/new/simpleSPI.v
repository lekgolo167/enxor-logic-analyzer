`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/08/2019 12:51:52 AM
// Design Name: 
// Module Name: simpleSPI
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


module simpleSPI(
    input clk,
    input MISO,
    input rd,
    input rst,
    output reg SCLK,
    output reg CS,
    output reg d_rdy,
    output reg [15:0] d
    );
    
    reg timer;
    reg t_rst;
    
    reg [2:0] state;
    reg [3:0] bit;
    reg [31:0] t_count;
    reg [31:0] sclk_count;
    
    initial begin
        state = 0;
        timer = 0;
        t_rst = 0;
        bit = 0;
        
        t_count = 0;
        sclk_count = 0;
        
        SCLK = 0;
        CS = 1;
        d = 0;
        d_rdy = 0;
    end
    
    //---------------------------
    // Clock Divider for SCLK:
    always @(posedge clk) begin
        if (sclk_count > 25) begin
            SCLK <= ~SCLK;
            sclk_count <= 0;
        end
        else begin
            sclk_count <= sclk_count + 1;
        end
    end
    //---------------------------
    
    //---------------------------
    // Timer Process
    always @(posedge SCLK) begin
        if (t_rst) begin
            timer <= 0;
            t_count <= 0;
        end
        else begin
            if (t_count > 10) begin
                timer <= 1;
            end
            else begin
                t_count <= t_count + 1;
            end
        end
    end
    //------------------------------
    
    //------------------------------
    // SPI State Machine
    localparam RESET = 0, INITIALIZE = 1, WAIT = 2, READ_SPI = 3, WAIT_ACK = 4;
    always @(posedge SCLK) begin
        if (!rst) begin
            state <= RESET;
        end
        else begin
            case (state)
                RESET: begin
                    d_rdy = 0;
                    CS <= 1;
                    t_rst <= 1;
                    state <= INITIALIZE;
                end
                INITIALIZE: begin
                    t_rst <= 0;
                    state <= WAIT;                
                end
                WAIT: begin
                    if (timer & rd) begin
                        CS <= 0;
                        bit <= 15;
                        state <= READ_SPI;
                    end                
                end
                READ_SPI: begin
                    if (bit > 0) begin
                        d[bit] <= MISO;
                        bit <= bit -1;
                    end
                    else begin
                        d[bit] <= MISO;
                        d_rdy <= 1;
                        CS <= 1;
                        state <= WAIT_ACK;
                    end                                
                end
                WAIT_ACK: begin
                    if (rd == 0) begin
                        t_rst <= 1;
                        d_rdy <= 0;
                        state <= INITIALIZE;
                    end
                    else begin
                        state <= WAIT_ACK;
                    end                                                
                end
                default: state <= RESET;
            endcase
        end
    end
    //-------------------------------
    
endmodule
