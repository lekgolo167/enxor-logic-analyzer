`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/07/2021 02:39:10 PM
// Design Name: 
// Module Name: top_testbench
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


module top_testbench(

    );
    
    wire tx, triggered_led;
    reg clk, rstn, rx;
    reg [15:0] count;

    parameter c_BIT_PERIOD      = 384;
    // Takes in input byte and serializes it 
    task UART_WRITE_BYTE;
        input [7:0] i_Data;
        integer     ii;
        begin
           
          // Send Start Bit
          rx <= 1'b0;
          #(c_BIT_PERIOD);
           
           
          // Send Data Byte
          for (ii=0; ii<8; ii=ii+1)
            begin
              rx <= i_Data[ii];
              #(c_BIT_PERIOD);
            end
           
          // Send Stop Bit
          rx <= 1'b1;
          #(c_BIT_PERIOD);
         end
    endtask // UART_WRITE_BYTE
    
    Logic_Analyzer_Top #(.DATA_WIDTH(8), .PACKET_WIDTH(16), .PRE_DEPTH(4), .POST_DEPTH(12)) LAT (
        .i_sys_clk(clk),
        .i_rstn(rstn),
        .i_raw_sig(count[15:8]),
        .i_rx(rx),
        .o_tx(tx),
        .o_triggered_led(triggered_led)
    );
    
    always
        #2 clk = ~clk;
        
    initial begin
        clk = 0;
        rstn = 0;
        count = 0;
        rx =1;
        #50 rstn = 1;

        @(posedge clk);
        // send scaler command
        UART_WRITE_BYTE(8'hFA);
        @(posedge clk);
        // send MSB
        UART_WRITE_BYTE(8'h00);
        @(posedge clk);
        // send scaler command
        UART_WRITE_BYTE(8'hFA);
        @(posedge clk);
        // send LSB
        UART_WRITE_BYTE(8'h03);
        @(posedge clk);
        
        // send channel command
        UART_WRITE_BYTE(8'hFB);
        @(posedge clk);
        // send channel 4
        UART_WRITE_BYTE(8'h04);
        @(posedge clk);
        
        // send trigger type command
        UART_WRITE_BYTE(8'hFC);
        @(posedge clk);
        // send positive edge
        UART_WRITE_BYTE(8'h01);
        @(posedge clk);
        
        // send enable command
        UART_WRITE_BYTE(8'hFD);
        @(posedge clk);
        // send enable
        UART_WRITE_BYTE(8'h01);
        @(posedge clk);

    end

    always @(posedge clk) begin
        count <= count + 1;
        
    end
    
endmodule