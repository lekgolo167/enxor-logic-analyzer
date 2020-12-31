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
    input i_enable, // No longer needed
    input i_triggered_state,
    input i_event,
    input i_r_ack,
    input i_start_read,
    input [PACKET_WIDTH-1:0] i_data,
    output reg o_post_read,
    output reg o_buffer_full, // Might be able to change this to an internal register
    output reg o_finished_read,
    output [PACKET_WIDTH-1:0] o_data,
    output reg o_t_rdy
);
    localparam DEPTH = (PRE_DEPTH + POST_DEPTH);
    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam PRE_ADDR_WIDTH = $clog2(PRE_DEPTH);
    localparam s_IDLE = 2'b00;
    localparam s_PRE_CAPTURE = 2'b01;
    localparam s_POST_CAPTURE = 2'b10;
    localparam s_WAIT = 2'b11;
    localparam s_READ_PRE = 2'b01;
    localparam s_READ_POST = 2'b10;

    reg r_wr_en;
    reg [2:0] r_wr_state, r_rd_state, r_prev_state;
    reg [PRE_ADDR_WIDTH-1:0] r_pre_last_adr;
    reg [ADDR_WIDTH-1:0] r_wr_adr, r_rd_adr;
        
    always @(posedge i_sys_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_wr_en <= 1;
            r_wr_adr <= 0;
            o_buffer_full <= 0;
            r_pre_last_adr <= 0;
            r_wr_state <= s_PRE_CAPTURE;
        end
        else begin
            case(r_wr_state)
                
                s_PRE_CAPTURE :
                    begin
                        r_wr_en <= 1;
                        o_buffer_full <= 0;
                        
                        if(i_triggered_state) begin
                            r_wr_state <= s_POST_CAPTURE;
                            r_pre_last_adr <= r_wr_adr;
                            r_wr_adr <= PRE_DEPTH;
                        end
                        else begin
                            if(i_event) begin
                                r_wr_adr <= (r_wr_adr + 1)  & {PRE_ADDR_WIDTH{1'b1}};
                            end
                        end
                    end
                
                s_POST_CAPTURE :
                    begin
                        if((r_wr_adr == (DEPTH - 1)) & i_event) begin // ANDed with event fills in the last memory slot
                            o_buffer_full <= 1;
                            r_wr_en <= 0;
                            r_wr_state <= s_WAIT;
                        end
                        else if(i_event) begin
                            r_wr_adr <= r_wr_adr + 1;
                        end
                    end

                s_WAIT:
                    begin
                        if(o_finished_read && !i_start_read) begin
                            o_buffer_full <= 0;
                            r_wr_adr <= 0;
                            r_wr_state <= s_IDLE;
                        end
                    end
                s_IDLE: 
                    begin
                        if(!i_triggered_state) begin
                            r_wr_state <= s_PRE_CAPTURE;
                        end
                    end    
                default :
                    r_wr_state <= s_PRE_CAPTURE;

            endcase    
        end
    end // End always
    
    always @(posedge i_sys_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            r_rd_adr <= 0;
            o_finished_read <= 0;
            o_t_rdy <= 0;
            r_rd_state <= s_IDLE;
            r_prev_state <= s_WAIT;
            o_post_read <= 0;
        end
        else begin
            case(r_rd_state)
                s_IDLE :
                    begin
                        if(!o_buffer_full) begin
                            o_finished_read <= 0;
                        end
                        if(i_start_read && !o_finished_read) begin
                            o_t_rdy <= 1;
                            r_rd_state <= s_READ_PRE;
                        end
                        r_rd_adr <= (r_pre_last_adr + 1) & {PRE_ADDR_WIDTH{1'b1}}; // Might not neet this ANDed anymorre because r_pre_last_adr will rollover
                        o_t_rdy <= 0;
                        o_post_read <= 0;
                    end
                s_READ_PRE:
                    begin
                        o_t_rdy <= 1;
                        
                        if((r_rd_adr == r_pre_last_adr) & i_r_ack) begin
                            o_t_rdy <= 0;
                            r_rd_state <= s_WAIT;
                            r_prev_state <= s_READ_POST;
                            r_rd_adr <= PRE_DEPTH;
                        end
                        else begin
                            if (i_r_ack) begin
                                o_t_rdy <= 0;
                                r_prev_state <= r_rd_state;
                                r_rd_state <= s_WAIT;
                                r_rd_adr <= (r_rd_adr + 1) & {PRE_ADDR_WIDTH{1'b1}};
                            end
                        end
                    end

                s_READ_POST:
                    begin
                        o_t_rdy <= 1;
                        o_post_read <= 1;
                        
                        // Use reduction AND here?
                        if((r_rd_adr == (DEPTH-1)) & i_r_ack) begin
                            o_t_rdy <= 0;
                            r_rd_state <= s_WAIT;
                            r_prev_state <= s_IDLE;
                            o_finished_read <= 1;
                        end
                        else if (i_r_ack) begin
                            o_t_rdy <= 0;
                            r_prev_state <= r_rd_state;
                            r_rd_state <= s_WAIT;
                            r_rd_adr <= r_rd_adr + 1;
                        end
                    end
                    
                s_WAIT:
                    begin
                        if (!i_r_ack) begin
                            r_rd_state <= r_prev_state;
                        end
                    end
                    
                default :
                    r_rd_state <= s_IDLE;

            endcase
            
        end
    end // End always
    
    sram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(PACKET_WIDTH), .DEPTH(DEPTH)) sram_0 (
        .i_sys_clk(i_sys_clk),
        .i_wr_en(r_wr_en & i_event),
        .i_wr_adr(r_wr_adr),
        .i_rd_adr(r_rd_adr),
        .i_data(i_data),
        .o_data(o_data)
    );
    
endmodule
