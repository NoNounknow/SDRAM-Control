//SDRAM SIZE = 8192X512X16
  //8192ROWS 512COLS 16BITS
module SDRAM_RD #(
    parameter SDRAM_COLS_MAX  = 128,
    parameter IMAGE_NEED_ROW  = 300, //300 = 640*480*8/16*512 
    parameter TIME_PRE_CHARGE_long = 10
)(
    input   wire        Sys_clk,
    input   wire        Rst_n  ,
    //VGA 640x480x60hz
    input   wire            VGA_CLOCK       ,
    output  reg             VGA_START       ,
    //FIFO
    input   wire            VGA_FIFO_RD_EN  ,
    output  wire    [ 7:0]  VGA_FIFO_RD_DATA,
    //CTRL 
    input   wire            WR_data_done    ,
    //SDRAM
    input   wire            INIT_DONE       ,
    output  reg     [ 3:0]  COMMAND_RD      ,
    output  reg     [11:0]  RD_A_ADDR       ,
    output  reg     [ 1:0]  RD_BANK_ADDR    ,
    output  wire            RD_DATA_DONE    ,
    output  reg             RD_req          ,
    input   wire            WR_req          ,
    input   wire            ARF_req         ,
    output  reg             Break_RD_other  ,
    input   wire            RD_access       ,
    input   wire    [15:0]  READ_SDRAM_DQ    
);
`include "D:/three_verilog/SDRAM/SDRAM_init/rtl/sdram_param.h"
            localparam  STATE_IDLE      = 5'b0_0001;
            localparam  STATE_RD_WAIT   = 5'b0_0010;
            localparam  STATE_ACT       = 5'b0_0100;
            localparam  STATE_RD_NOW    = 5'b0_1000;
            localparam  STATE_Precharge = 5'b1_0000;
            reg     [ 4:0]       STATE         ;
            reg     [ 1:0]       CNT_ACT       ;
            reg     [ 9:0]       CNT_SDRAM_COLS;
            reg     [12:0]       CNT_SDRAM_ROWS;
            wire                 ROWS_END_Flag ;
            reg     [ 1:0]       CNT_Brust     ;
            reg     [ 3:0]       CNT_Precharge ;
            reg                  Done_image    ;
    //FIFO
            wire                 FIFO_FULL     ;
            wire                 FIFO_EMPTY    ;
            wire    [11:0]       FIFO_RD_cnt   ;
            wire    [10:0]       FIFO_WR_cnt   ;
            wire    [15:0]       FIFO_WR_data  ;
            reg                  FIFO_WR_EN    ;
            reg     [ 3:0]       FIFO_WR_delay ;
    //SIM
            reg                  Time_to_Read  ;
    assign FIFO_WR_data = READ_SDRAM_DQ;
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            Time_to_Read <= 'd0;
        end else if(WR_data_done == 'd1) begin
            Time_to_Read <= 'd1;
        end else begin
            Time_to_Read <= Time_to_Read;
        end
    end
//FIFO_WR_EN INIT_CAS_Latency = 3
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            FIFO_WR_EN <= 'd0;
        end else if(STATE == STATE_RD_NOW) begin
            FIFO_WR_EN <= 1'b1;
        end else begin
            FIFO_WR_EN <= 'd0;
        end
    end
    always @(posedge Sys_clk or negedge Rst_n) begin
    if(Rst_n == 'd0) begin
        FIFO_WR_delay <= 'd0;
    end else begin
        FIFO_WR_delay <= {FIFO_WR_delay[2:0],FIFO_WR_EN};
    end
end
//VGA_START
    always @(posedge VGA_CLOCK) begin
        if(Rst_n == 'd0) begin
            VGA_START <= 'd0;
        end else if(FIFO_RD_cnt >= 'd640) begin
            VGA_START <= 'd1;
        end else begin
            VGA_START <= VGA_START;
        end
     end
//RD_req:FIFO_WR_cnt <= 'd320时，从SDRAM读取数据给FIFO
    //640x480 一行为640x8bits数据 
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            RD_req <= 'd0;
        end else if(FIFO_WR_cnt <= 'd512 
                && STATE == STATE_RD_WAIT
                && Time_to_Read ==1
                && Done_image == 'd0) begin
            RD_req <= 1'b1;
        end else if(Break_RD_other == 1'b1 
                && STATE == STATE_RD_WAIT
                && FIFO_WR_cnt <= 'd512) begin 
            RD_req <= 1'd1;
        end else if(Done_image == 1'b1 || RD_access == 1'b1 || STATE != STATE_RD_WAIT) begin
            RD_req <= 'd0;
        end else begin
            RD_req <= RD_req;
        end
    end
//Done_image
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            Done_image <= 'd0;
        end else if(STATE == STATE_RD_NOW
        && (CNT_SDRAM_ROWS == IMAGE_NEED_ROW - 1'b1 )
        && (CNT_SDRAM_COLS == SDRAM_COLS_MAX - 1'b1)    
        && (CNT_Brust == INIT_Burst_length -2'd2)) begin
            Done_image <= 1'b1;
        end else if(STATE == STATE_Precharge 
            && CNT_Precharge == TIME_PRE_CHARGE_long) begin
            Done_image <= 'd0;
        end else begin
            Done_image <= Done_image;
        end
    end
//RD_DATA_DONE
    assign RD_DATA_DONE = (STATE == STATE_Precharge 
        && CNT_Precharge == TIME_PRE_CHARGE_long 
        && Done_image == 1'b1);
//Break_RD_other
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            Break_RD_other <= 'd0;
        end else if(STATE == STATE_Precharge 
        && CNT_Precharge == TIME_PRE_CHARGE_long 
        && Done_image == 1'b0) begin
            Break_RD_other <= 'd1;
        end else if(RD_req == 1'b1)begin
            Break_RD_other <= 'd0;
        end else begin
            Break_RD_other <= Break_RD_other;
        end
    end
//CNT_ACT
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            CNT_ACT <= 'd0;
        end else if(STATE == STATE_ACT) begin
            if(CNT_ACT == TIME_RCD) begin
                CNT_ACT <= 'd0; 
            end else begin
                CNT_ACT <= CNT_ACT + 1'b1;
            end
        end else begin
            CNT_ACT <= 'd0;
        end
    end
//CNT_Brust
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            CNT_Brust <= 'd0;
        end else if(STATE == STATE_RD_NOW) begin
            if(CNT_Brust == INIT_Burst_length -1'b1) begin
                CNT_Brust <= 'd0;
            end else begin
                CNT_Brust <= CNT_Brust + 1'b1;
            end
        end else begin
            CNT_Brust <= 'd0;
        end
    end
//CNT_SDRAM_ROWS
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            CNT_SDRAM_ROWS <= 'd0;
        end else if(STATE == STATE_RD_NOW) begin
            if (CNT_SDRAM_ROWS == IMAGE_NEED_ROW - 1'b1 
            && (CNT_SDRAM_COLS == SDRAM_COLS_MAX - 1'b1)
            && (CNT_Brust == INIT_Burst_length -1'b1)) begin
                CNT_SDRAM_ROWS <= 'd0;
            end else if((CNT_SDRAM_COLS == SDRAM_COLS_MAX - 1'b1)
                     && (CNT_Brust == INIT_Burst_length -1'b1)) begin
                CNT_SDRAM_ROWS <= CNT_SDRAM_ROWS + 1'b1;
            end else begin
                CNT_SDRAM_ROWS <= CNT_SDRAM_ROWS;
            end
        end else begin
            CNT_SDRAM_ROWS <= CNT_SDRAM_ROWS;
        end
    end
//CNT_SDRAM_COLS
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            CNT_SDRAM_COLS <= 'd0;
        end else if(STATE == STATE_RD_NOW) begin
            if((CNT_SDRAM_COLS == SDRAM_COLS_MAX - 1'b1) 
            && (CNT_Brust == INIT_Burst_length -1'b1)) begin
                CNT_SDRAM_COLS <= 'd0;
            end else if(CNT_Brust == INIT_Burst_length -1'b1) begin
                CNT_SDRAM_COLS <= CNT_SDRAM_COLS + 1'b1;
            end else begin
                CNT_SDRAM_COLS <= CNT_SDRAM_COLS;
            end
        end else begin
            CNT_SDRAM_COLS <= CNT_SDRAM_COLS;
        end
    end
assign ROWS_END_Flag  = (STATE == STATE_RD_NOW) 
    && (CNT_SDRAM_COLS == SDRAM_COLS_MAX - 1'b1) 
    && (CNT_Brust == INIT_Burst_length -1'b1);
//CNT_Precharge
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            CNT_Precharge <= 'd0;
        end else if(STATE == STATE_Precharge && CNT_Precharge == TIME_PRE_CHARGE_long) begin
            CNT_Precharge <= 'd0;
        end else if(STATE == STATE_Precharge) begin
            CNT_Precharge <= CNT_Precharge + 1'b1;
        end else begin
            CNT_Precharge <= CNT_Precharge;
        end
    end
//COMMAND
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            COMMAND_RD   <= COMMAND_NOP;
            RD_A_ADDR    <= 12'd0      ;
            RD_BANK_ADDR <= 2'b00      ;
        end else if(STATE == STATE_RD_WAIT && RD_access == 1'b1) begin
            COMMAND_RD   <= COMMAND_ACT;
            RD_A_ADDR    <= CNT_SDRAM_ROWS;//row_addr
            RD_BANK_ADDR <= 2'b00      ;
        end else if(STATE == STATE_RD_NOW  && CNT_Brust  == 'd0 && ROWS_END_Flag == 'd0) begin
            COMMAND_RD   <= COMMAND_READ;
            RD_A_ADDR    <= CNT_SDRAM_COLS<<2'd2;
            RD_BANK_ADDR <= 2'b00      ;
        end else if(STATE == STATE_Precharge && CNT_Precharge == 'd2) begin
            COMMAND_RD <= COMMAND_PRE;
            RD_A_ADDR[10]<= 1'b1       ;
            RD_BANK_ADDR <= 2'b00      ;
        end else begin
            COMMAND_RD   <= COMMAND_NOP;
            RD_A_ADDR    <= 12'd0      ;
            RD_BANK_ADDR <= 2'b00      ;
        end
    end
//STATE
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            STATE <= STATE_IDLE;
        end else begin
            case (STATE)
                STATE_IDLE: begin
                    if(INIT_DONE == 1'b1) begin
                        STATE <= STATE_RD_WAIT;
                    end else begin
                        STATE <= STATE_IDLE;
                    end
                end
                STATE_RD_WAIT: begin
                    if(RD_access == 1'b1) begin
                        STATE <= STATE_ACT;
                    end else begin
                        STATE <= STATE_RD_WAIT;
                    end
                end
                STATE_ACT: begin
                    if((ARF_req == 1'b1 || WR_req == 1'b1) && CNT_ACT == TIME_RCD) begin
                        STATE <= STATE_Precharge;
                    end else if(CNT_ACT == TIME_RCD) begin
                        STATE <= STATE_RD_NOW;
                    end else begin
                        STATE <= STATE_ACT;
                    end
                end
                STATE_RD_NOW:begin
                    if((ARF_req == 1'b1 || WR_req == 1'b1) 
                    && CNT_Brust == INIT_Burst_length - 1'b1) begin
                        STATE <= STATE_Precharge;
                    end else if(ROWS_END_Flag == 1'b1) begin
                        STATE <= STATE_Precharge;
                    end else if(Done_image == 1'b1) begin
                        STATE <= STATE_Precharge;
                    end else begin
                        STATE <= STATE_RD_NOW;
                    end
                end
                STATE_Precharge: begin
                    if(CNT_Precharge == TIME_PRE_CHARGE_long) begin
                        STATE <= STATE_RD_WAIT;
                    end else begin
                        STATE <=  STATE_Precharge;
                    end
                end
                default: begin
                    STATE <= STATE_IDLE;
                end
            endcase
        end
    end
/*------------------------------------------------------------------------*/
AS_FIFO_w2048x16_r4096x8 Inst_AS_FIFO_w2048x16_r4096x8 (
  .wr_clk       ( Sys_clk         ), // input wr_clk
  .rd_clk       ( VGA_CLOCK       ), // input rd_clk
  .din          ( FIFO_WR_data    ), // input [15 : 0] din
  .wr_en        ( FIFO_WR_delay[3]), // input wr_en
  .rd_en        ( VGA_FIFO_RD_EN  ), // input rd_en
  .dout         ( VGA_FIFO_RD_DATA), // output [7 : 0] dout
  .full         ( FIFO_FULL       ), // output full
  .empty        ( FIFO_EMPTY      ), // output empty
  .rd_data_count( FIFO_RD_cnt     ), // output [11 : 0] rd_data_count
  .wr_data_count( FIFO_WR_cnt     )  // output [10 : 0] wr_data_count
);
/*------------------------------------------------------------------------*/
endmodule