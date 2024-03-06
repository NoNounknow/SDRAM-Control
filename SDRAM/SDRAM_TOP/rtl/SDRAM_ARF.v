module SDRAM_ARF #(

)(
    input   wire        Sys_clk,
    input   wire        Rst_n  ,
    //SDRAM
    input   wire            INIT_DONE     ,
    output  reg     [3:0]   COMMAND_REF   ,
    output  reg     [11:0]  ARF_A_ADDR    ,
    output  reg     [ 1:0]  ARF_BANK_ADDR ,
    output  reg             REF_DONE      ,
    output  reg             ARF_req       ,
    input   wire            ARF_access    
);
`include "D:/three_verilog/SDRAM/SDRAM_init/rtl/sdram_param.h"
    localparam  TIME_ARF_BEGIN   = 1'b1                  ;
    // localparam  TIME_PRE_to_ARF  = 1'b1 + TIME_PRE_CHARGE;
    // localparam  TIME_ARF_to_done = 1'b1 + TIME_PRE_CHARGE + TIME_Auto_refresh;
    localparam  TIME_ARF_to_done = 'd9;
            reg  [9:0]  ARF_CNT    ;
            reg  [3:0]  COMMAND_CNT;
//ARF_CNT
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            ARF_req <= 'd0;
        end else if(ARF_access == 1'b1) begin
            ARF_req <= 1'b0;
        end else if(ARF_CNT == ARF_PERIOD) begin
            ARF_req <= 1'b1;
        end
    end
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            ARF_CNT <= 'd0;
        end else if(INIT_DONE == 1'b1) begin
            ARF_CNT <= 'd1;
        end else if(ARF_CNT == ARF_PERIOD) begin
            ARF_CNT <= 'd1;
        end else if(ARF_CNT > 'd0) begin
            ARF_CNT <= ARF_CNT + 1'd1;
        end else begin
            ARF_CNT <= ARF_CNT;
        end
    end
always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            REF_DONE <= 1'b0;
        end else if(COMMAND_CNT == TIME_ARF_to_done) begin
            REF_DONE <= 1'b1;
        end else begin
            REF_DONE <= 1'b0;
        end
    end
//COMMAND_CNT
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            COMMAND_CNT <= 'd0;
        end else if(ARF_access == 1'b1) begin
            COMMAND_CNT <= 'd1;
        end else if(COMMAND_CNT == TIME_ARF_to_done) begin
            COMMAND_CNT <= 'd0;
        end else if(COMMAND_CNT > 'd0) begin
            COMMAND_CNT <= COMMAND_CNT + 1'b1;
        end else begin
            COMMAND_CNT <= COMMAND_CNT;
        end
    end
//COMMAND
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            COMMAND_REF   <= COMMAND_NOP;
            ARF_A_ADDR    <= 12'd0      ;
            ARF_BANK_ADDR <= 2'b00      ;
        end else if(COMMAND_CNT == TIME_ARF_BEGIN) begin
            COMMAND_REF   <= COMMAND_ARF;
        end else begin
            COMMAND_REF   <= COMMAND_NOP;
            ARF_A_ADDR    <= 12'd0      ;
            ARF_BANK_ADDR <= 2'b00      ;
        end
    end
//COMMAND other SDRAM
    // always@(posedge Sys_clk or negedge Rst_n) begin
    //     if(Rst_n == 'd0) begin
    //         COMMAND_REF   <= COMMAND_NOP;
    //         ARF_A_ADDR    <= 12'd0      ;
    //         ARF_BANK_ADDR <= 2'b00      ;
    //     end else begin
    //         case (COMMAND_CNT)
    //             TIME_ARF_BEGIN:  begin
    //                 COMMAND_REF    <= COMMAND_PRE;
    //                 ARF_A_ADDR[10] <= 1'b1       ;
    //             end
    //             TIME_PRE_to_ARF: begin
    //                 COMMAND_REF   <= COMMAND_ARF;
    //             end
    //             default: begin
    //                 COMMAND_REF   <= COMMAND_NOP;
    //                 ARF_A_ADDR    <= 12'd0      ;
    //                 ARF_BANK_ADDR <= 2'b00      ;
    //             end
    //         endcase
    //     end
    // end
endmodule
