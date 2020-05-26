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


module Post_Trig_Buffer #(FIFO_PTR = 4, FIFO_WIDTH = 32, FIFO_DEPTH = 16) (
    input i_sys_clk,
    input i_rstn,
    input i_fifo_wren,
    input [FIFO_WIDTH-1:0] i_fifo_wrdata,
    input i_fifo_rden,
    output [FIFO_WIDTH-1:0] o_fifo_rddata,
    output o_fifo_full,
    output o_fifo_empty,
    output [FIFO_PTR:0] o_fifo_room_avail,
    output [FIFO_PTR:0]  o_fifo_data_avail
);

    reg [FIFO_PTR-1:0] wr_ptr, wr_ptr_nxt;
    reg [FIFO_PTR-1:0] rd_ptr, rd_ptr_nxt;
    reg [FIFO_PTR:0] num_entries, num_entries_nxt;
    reg fifo_full, fifo_empty;
    wire fifo_full_nxt, fifo_empty_nxt;
    reg [FIFO_PTR:0] fifo_room_avail;
    wire [FIFO_PTR:0] fifo_room_avail_nxt;
    wire [FIFO_PTR:0] fifo_data_avail;
    
    // Write-pointer control logic
    // ************************************************
    always @(*) begin
        wr_ptr_nxt = wr_ptr;
        if(i_fifo_wren) begin
            if(wr_ptr == (FIFO_DEPTH - 1)) begin
                wr_ptr_nxt = 0;
            end
            else begin
                wr_ptr_nxt = wr_ptr + 1;
            end
        end
    end // End always

    // Read-pointer control logic
    // ************************************************
    always @(*) begin
        rd_ptr_nxt = rd_ptr;
        if(i_fifo_rden) begin
            if(rd_ptr == (FIFO_DEPTH -1)) begin
                rd_ptr_nxt = 0;
            end
            else begin
                rd_ptr_nxt = rd_ptr + 1;
            end
        end
    end // End always
    
    // Calculate number of occupied entries in the FIFO
    // ************************************************
    always @(*) begin
        num_entries_nxt = num_entries;
        if(i_fifo_wren && i_fifo_rden) begin // no change to num_entries
            num_entries_nxt = num_entries;
        end
        else if(i_fifo_wren) begin
            num_entries_nxt = num_entries + 1;
        end
        else if(i_fifo_rden) begin
            num_entries_nxt = num_entries - 1;
        end
    end // End always
    
    assign fifo_full_nxt = (num_entries_nxt == FIFO_DEPTH);
    assign fifo_empty_nxt = (num_entries_nxt == 0);
    assign o_fifo_data_avail = num_entries;
    assign fifo_room_avail_nxt = (FIFO_DEPTH - num_entries_nxt);
    
    // ************************************************
    always @(posedge i_sys_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            num_entries <= 0;
            fifo_full <= 0;
            fifo_empty <= 1;
            fifo_room_avail <= FIFO_DEPTH;
        end
        else begin
            wr_ptr <= wr_ptr_nxt;
            rd_ptr <= rd_ptr_nxt;
            num_entries <= num_entries_nxt;
            fifo_full <= fifo_full_nxt;
            fifo_empty <= fifo_empty_nxt;
            fifo_room_avail <= fifo_room_avail_nxt;
        end
    end // End always
    
    sram #(.ADDR_WIDTH(FIFO_PTR), .DATA_WIDTH(FIFO_WIDTH), .DEPTH(FIFO_DEPTH)) sram_1 (
        .i_sys_clk(i_sys_clk),
        .i_wr_en(),
        .i_wr_adr(),
        .i_rd_adr(),
        .i_data(),
        .o_data()
    );
    
endmodule