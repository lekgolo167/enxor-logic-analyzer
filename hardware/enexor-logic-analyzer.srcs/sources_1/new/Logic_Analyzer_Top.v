`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/06/2020 10:28:46 PM
// Design Name: 
// Module Name: Logic_Analyzer_Top
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


module Logic_Analyzer_Top(
    input channels [7:0],
    input m_clk,
    input rx,
    output triggered_led,
    output tx
);

Pulse_Sync PS (

);

Clock_Divider CD (

);

Timestamp_Counter TSC (

);

Trigger_Controller TC (
    .data_in(),
    .channel_select(),
    .trigger_type(),
    .enable(),
    .rst(),
    .clk(),
    .slow_clk_posedge(),
    .triggered(),
    .event_pulse(),
    .data_out()
    );
    
endmodule
