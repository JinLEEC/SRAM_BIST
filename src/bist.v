`timescale 1ns / 1ps
module bist(
    input                clock,
    input                n_reset,
    input                bist_en, // bist enable
    input        [9:0]   rd_data, // read data from sram
    output               csn,     // sram enable, csn = 0 -> sram enable / csn = 1 -> sram not active 
    output  reg          wen,     // write enable, wen = 0 -> write / wen = 1 -> read
    output  reg  [9:0]   wr_data, // write data to sram
    output  reg  [7:0]   wr_addr, // w/r address
    output  reg          b_done, 
    output  reg          b_err    
);

// Parameter 
parameter value_3ff = 10'h3FF;
parameter value_00  = 10'h00;
parameter value_2aa = 10'h2AA;

// Define states
reg [2:0] state;
parameter IDLE    = 3'd0;
parameter WRITE_1 = 3'd1;
parameter READ_1  = 3'd2;
parameter WRITE_2 = 3'd3;
parameter READ_2  = 3'd4;
parameter WRITE_3 = 3'd5;
parameter READ_3  = 3'd6;

// State flag
wire idle_flag    = (state == IDLE)    ? 1'b1 : 1'b0;
wire write_1_flag = (state == WRITE_1) ? 1'b1 : 1'b0;
wire read_1_flag  = (state == READ_1)  ? 1'b1 : 1'b0;
wire write_2_flag = (state == WRITE_2) ? 1'b1 : 1'b0;
wire read_2_flag  = (state == READ_2)  ? 1'b1 : 1'b0;
wire write_3_flag = (state == WRITE_3) ? 1'b1 : 1'b0;
wire read_3_flag  = (state == READ_3)  ? 1'b1 : 1'b0;

// State transition
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        state <= 3'b0;
    else
        state <= (idle_flag      & bist_en_posedge)      ? WRITE_1 : 
                 (write_1_flag   & (wr_addr == 8'd255))  ? READ_1  : 
                 (read_1_flag    & (wr_addr == 8'd255))  ? WRITE_2 : 
                 (write_2_flag   & (wr_addr == 8'd255))  ? READ_2  :
                 (read_2_flag    & (wr_addr == 8'd255))  ? WRITE_3 :
                 (write_3_flag   & (wr_addr == 8'd255))  ? READ_3  :
                 (read_3_flag_1d & (wr_addr == 8'd0  ))  ? IDLE    : state;


//---------------------------------------------------------------------------------------------------------
// bist_en syncoronized to clock
reg bist_en_1d, bist_en_2d;
wire bist_en_posedge = bist_en_1d & ~bist_en_2d;
always@(negedge n_reset, posedge clock)
    if(!n_reset) begin
        bist_en_1d <= 1'b0;
        bist_en_2d <= 1'b0;
    end
    else begin
        bist_en_1d <= bist_en;
        bist_en_2d <= bist_en_1d;
    end

// csn
assign csn = (state == IDLE) ? 1'b1 : 1'b0;

// wr_addr
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        wr_addr <= 8'b0;
    else
        wr_addr <=  (write_1_flag & (wr_addr != 8'd255)) ? wr_addr + 1'b1 :
                    (read_1_flag  & (wr_addr != 8'd255)) ? wr_addr + 1'b1 :
                    (write_2_flag & (wr_addr != 8'd255)) ? wr_addr + 1'b1 :
                    (read_2_flag  & (wr_addr != 8'd255)) ? wr_addr + 1'b1 :
                    (write_3_flag & (wr_addr != 8'd255)) ? wr_addr + 1'b1 :
                    (read_3_flag  & (wr_addr != 8'd255)) ? wr_addr + 1'b1 : 8'b0;  

// addr_cnt
reg [7:0] addr_cnt;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        addr_cnt <= 8'b0;
    else
        addr_cnt <= wr_addr;


// wr_data
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        wr_data <= 10'b0;
    else
        wr_data <= (bist_en_posedge) ? value_3ff :
                   (read_1_flag & (wr_addr == 8'd255)) ? value_00 :
                   (read_2_flag  & (wr_addr == 8'd255)) ? value_2aa : wr_data;

// wen
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        wen <= 1'b0;
    else
        wen <= (~bist_en) ? 1'b0 :
               (write_1_flag & (wr_addr == 8'd255)) ? 1'b1 :
               (read_1_flag  & (wr_addr == 8'd255)) ? 1'b0 :
               (write_2_flag & (wr_addr == 8'd255)) ? 1'b1 :
               (read_2_flag  & (wr_addr == 8'd255)) ? 1'b0 :
               (write_3_flag & (wr_addr == 8'd255)) ? 1'b1 :
               (read_3_flag  & (wr_addr == 8'd255)) ? 1'b1 : wen;

// expected value 
reg [9:0] expected_value;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        expected_value <= 10'b0;
    else
        expected_value <= ((wen == 1'b0) & write_1_flag) ? value_3ff :
                          ((wen == 1'b0) & write_2_flag) ? value_00  :
                          ((wen == 1'b0) & write_3_flag) ? value_2aa : expected_value;                   

// read_1_flag_1d
reg read_1_flag_1d;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        read_1_flag_1d <= 1'b0;
    else
        read_1_flag_1d <= read_1_flag;

// read_2_flag_1d
reg read_2_flag_1d;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        read_2_flag_1d <= 1'b0;
    else
        read_2_flag_1d <= read_2_flag;

// read_3_flag_1d
reg read_3_flag_1d;
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        read_3_flag_1d <= 1'b0;
    else
        read_3_flag_1d <= read_3_flag;

// b_done
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        b_done <= 1'b0;
    else
        b_done <= ((addr_cnt == 8'd255) & read_3_flag_1d) ? 1'b1 : 1'b0;

// b_err when rd_data != expected value
always@(negedge n_reset, posedge clock)
    if(!n_reset)
        b_err <= 1'b0;
    else
        b_err <= ((wen == 1'b1) & read_1_flag_1d & (rd_data != expected_value))  ? 1'b1 :
                 ((wen == 1'b1) & read_2_flag_1d & (rd_data != expected_value))  ? 1'b1 :
                 ((wen == 1'b1) & read_3_flag_1d & (rd_data != expected_value))  ? 1'b1 : 1'b0; 

endmodule
