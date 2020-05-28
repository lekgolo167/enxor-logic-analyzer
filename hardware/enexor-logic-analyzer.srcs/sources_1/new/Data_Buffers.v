`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2020 02:12:42 PM
// Design Name: 
// Module Name: Data_Buffers
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


module Data_Buffers #(PACKET_WIDTH = 16, PRE_DEPTH = 4, POST_DEPTH = 12)(
    input i_sys_clk,
    input i_rstn,
    input i_enable,
    input i_triggered_state,
    input i_wr_en,
    input i_rd_en,
    input [PACKET_WIDTH-1:0] i_data,
    output reg o_done,
    output [PACKET_WIDTH-1:0] o_data
);
    localparam DEPTH = (PRE_DEPTH + POST_DEPTH);
    localparam ADDR_WIDTH = $clog2(DEPTH);

    localparam s_IDLE = 3'b00;
    localparam s_PRE_CAPTURE = 3'b001;
    localparam s_POST_CAPTURE = 3'b010;
    localparam s_WAIT = 3'b011;
    localparam s_READ_PRE = 3'b100;
    localparam s_READ_POST = 3'b101;

    reg [2:0] r_state;
    reg [PRE_DEPTH-1:0] r_pre_last_adr;
    reg [ADDR_WIDTH-1:0] r_wr_adr, r_rd_adr;
        
    always @(posedge i_sys_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_wr_adr <= 0;
            r_state <= s_IDLE;
        end
        else begin
            case(r_state)
                s_IDLE :
                    begin
                        o_done <= 0;
                        if(i_enable) begin
                            r_state <= s_PRE_CAPTURE;
                        end
                    end
                
                s_PRE_CAPTURE :
                    begin
                        if(i_triggered_state) begin
                            r_state <= s_POST_CAPTURE;
                            r_pre_last_adr <= r_wr_adr + 1;
                            r_wr_adr <= PRE_DEPTH;
                        end
                        else if(i_wr_en) begin
                            r_wr_adr <= r_wr_adr + 1;
                        end
                    end
                
                s_POST_CAPTURE :
                    begin
                        if(r_wr_adr == (DEPTH - 1)) begin // maybe r_wr == 0 and then i_wr_en & ~done
                            o_done <= 1;
                            r_state <= s_WAIT;
                        end
                        else if(i_wr_en) begin
                            r_wr_adr <= r_wr_adr + 1;
                        end
                    end

                s_WAIT:
                    begin
                        if(i_rd_en) begin
                            r_rd_adr <= r_pre_last_adr + 1;
                            r_state <= s_READ_PRE;
                        end
                    end

                s_READ_PRE:
                    begin
                        if(r_rd_adr == PRE_DEPTH) begin
                            r_rd_adr <= 0;
                        end
                        else if (i_rd_en) begin
                            r_rd_adr <= r_rd_adr + 1;
                        end
                        if(r_rd_adr == r_pre_last_adr) begin
                            r_state <= s_READ_POST;
                            r_rd_adr <= PRE_DEPTH;
                        end
                    end

                s_READ_POST:
                    begin
                        if(r_rd_adr == (POST_DEPTH-1)) begin
                            r_state <= s_IDLE;
                            o_done <= 1;
                        end
                        else if (i_rd_en) begin
                            r_rd_adr <= r_rd_adr + 1;
                        end
                    end

                default :
                    r_state <= s_IDLE;

            endcase
            
        end
    end // End always
    
    sram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(PACKET_WIDTH), .DEPTH(DEPTH)) sram_0 (
        .i_sys_clk(i_sys_clk),
        .i_wr_en(i_wr_en),
        .i_wr_adr(r_wr_adr),
        .i_rd_adr(r_rd_adr),
        .i_data(i_data),
        .o_data(o_data)
    );
    
endmodule
