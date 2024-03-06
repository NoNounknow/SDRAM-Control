//SDRAM SIZE = 8192X512X16
  //8192ROWS 512COLS 16BITS
module SDRAM_WR #(
    parameter SDRAM_COLS_MAX  = 128,
    parameter IMAGE_NEED_ROW  = 300, //300 = 640*480*8/16*512 
    parameter TIME_PRE_CHARGE_long = 8
)(
    input   wire        Sys_clk,
    input   wire        Rst_n  ,
    //FIFO
    input   wire            FIFO_WR_EN   ,//8bits
    input   wire    [ 7:0]  FIFO_WR_data ,
    //SDRAM
    input   wire            INIT_DONE    ,
    output  reg     [ 3:0]  COMMAND_WR   ,
    output  reg     [11:0]  WR_A_ADDR    ,
    output  reg     [ 1:0]  WR_BANK_ADDR ,
    output  wire            WR_data_done ,
    output  reg             WR_req       ,
    input   wire            ARF_req      ,
    output  reg             Break_WR_to_ARF,
    input   wire            WR_access    ,
    output  wire    [15:0]  WRITE_SDRAM_DQ    
);
`include "D:/three_verilog/SDRAM/SDRAM_init/rtl/sdram_param.h"
            localparam  STATE_IDLE      = 5'b0_0001;
            localparam  STATE_WR_wait   = 5'b0_0010;
            localparam  STATE_ACT       = 5'b0_0100;
            localparam  STATE_WR_NOW    = 5'b0_1000;
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
            wire    [10:0]       FIFO_RD_cnt   ;
            reg                  FIFO_RD_EN    ;
            wire    [15:0]       FIFO_RD_DATA  ;
    assign WRITE_SDRAM_DQ = FIFO_RD_DATA;
//FIFO_RD_EN
always @(posedge Sys_clk or negedge Rst_n) begin
    if(Rst_n == 'd0) begin
        FIFO_RD_EN <= 'd0;
    end else if(STATE == STATE_WR_NOW) begin
        FIFO_RD_EN <= 1'b1;
    end else begin
        FIFO_RD_EN <= 'd0;
    end
end
//WR_req
    always @(posedge Sys_clk or negedge Rst_n) begin
    if(Rst_n == 'd0) begin
        WR_req <= 'd0;
    end else if(FIFO_RD_cnt >= 512 && STATE == STATE_WR_wait) begin
        WR_req <= 1'b1;
    end else if(Break_WR_to_ARF 
        && CNT_SDRAM_ROWS == IMAGE_NEED_ROW - 1'b1 
        && ((FIFO_RD_cnt >>2'd2) >= (SDRAM_COLS_MAX - CNT_SDRAM_COLS))) begin 
        WR_req <= 1'd1;
    end else if(Done_image == 1'b1 || WR_access == 1'b1 || STATE != STATE_WR_wait) begin
        WR_req <= 'd0;
    end else begin
        WR_req <= WR_req;
    end
end
//Done_image
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            Done_image <= 'd0;
        end else if(STATE == STATE_WR_NOW
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
//WR_data_done
    assign WR_data_done = (STATE == STATE_Precharge 
        && CNT_Precharge == TIME_PRE_CHARGE_long 
        && Done_image == 1'b1);
//Break_WR_to_ARF
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            Break_WR_to_ARF <= 'd0;
        end else if(STATE == STATE_Precharge 
        && CNT_Precharge == TIME_PRE_CHARGE_long 
        && Done_image == 1'b0) begin
            Break_WR_to_ARF <= 'd1;
        end else if(WR_req == 1'b1)begin
            Break_WR_to_ARF <= 'd0;
        end else begin
            Break_WR_to_ARF <= Break_WR_to_ARF;
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
        end else if(STATE == STATE_WR_NOW) begin
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
        end else if(STATE == STATE_WR_NOW) begin
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
        end else if(STATE == STATE_WR_NOW) begin
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
assign ROWS_END_Flag  = (STATE == STATE_WR_NOW) && (CNT_SDRAM_COLS == SDRAM_COLS_MAX - 1'b1) && (CNT_Brust == INIT_Burst_length -1'b1);
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
            COMMAND_WR   <= COMMAND_NOP;
            WR_A_ADDR    <= 12'd0      ;
            WR_BANK_ADDR <= 2'b00      ;
        end else if(STATE == STATE_WR_wait && WR_access == 1'b1) begin
            COMMAND_WR   <= COMMAND_ACT;
            WR_A_ADDR    <= CNT_SDRAM_ROWS;//row_addr
            WR_BANK_ADDR <= 2'b00      ;
        end else if(STATE == STATE_WR_NOW  && CNT_Brust  == 'd0) begin
            COMMAND_WR   <= COMMAND_WRITE;
            WR_A_ADDR    <= CNT_SDRAM_COLS<<2'd2;
            WR_BANK_ADDR <= 2'b00      ;
        end else if(STATE == STATE_Precharge && CNT_Precharge == 'd0) begin
            COMMAND_WR   <= COMMAND_PRE;
            WR_A_ADDR[10]<= 1'b1       ;
            WR_BANK_ADDR <= 2'b00      ;
        end else begin
            COMMAND_WR   <= COMMAND_NOP;
            WR_A_ADDR    <= 12'd0      ;
            WR_BANK_ADDR <= 2'b00      ;
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
                        STATE <= STATE_WR_wait;
                    end else begin
                        STATE <= STATE_IDLE;
                    end
                end
                STATE_WR_wait: begin
                    if(WR_access == 1'b1) begin
                        STATE <= STATE_ACT;
                    end else begin
                        STATE <= STATE_WR_wait;
                    end
                end
                STATE_ACT: begin
                    if(ARF_req == 1'b1 && CNT_ACT == TIME_RCD) begin
                        STATE <= STATE_Precharge;
                    end else if(CNT_ACT == TIME_RCD) begin
                        STATE <= STATE_WR_NOW;
                    end else begin
                        STATE <= STATE_ACT;
                    end
                end
                STATE_WR_NOW:begin
                    if(ARF_req == 1'b1 && CNT_Brust == INIT_Burst_length - 1'b1) begin
                        STATE <= STATE_Precharge;
                    end else if(ROWS_END_Flag == 1'b1) begin
                        STATE <= STATE_Precharge;
                    end else if(Done_image == 1'b1) begin
                        STATE <= STATE_Precharge;
                    end else begin
                        STATE <= STATE_WR_NOW;
                    end
                end
                STATE_Precharge: begin
                    if(CNT_Precharge == TIME_PRE_CHARGE_long) begin
                        STATE <= STATE_WR_wait;
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
AS_FIFO_w2048x8_r1024x16 INST0_AS_FIFO_w2048x8_r1024x16 (
  .wr_clk       ( Sys_clk       ), // input wr_clk
  .rd_clk       ( Sys_clk       ), // input rd_clk
  .din          ( FIFO_WR_data  ), // input [7 : 0] din
  .wr_en        ( FIFO_WR_EN    ), // input wr_en
  .rd_en        ( FIFO_RD_EN    ), // input rd_en
  .dout         ( FIFO_RD_DATA  ), // output [15 : 0] dout
  .full         ( FIFO_FULL     ), // output full
  .empty        ( FIFO_EMPTY    ), // output empty
  .rd_data_count( FIFO_RD_cnt   )  // output [9 : 0] rd_data_count
  /*------------------------------------------------------------------------*/
);
endmodule