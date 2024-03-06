module SDRAM_INIT(
    input   wire            Sys_clk       ,
    input   wire            Rst_n         ,
    output  reg     [ 3:0]  COMMAND_INIT  ,//COMMAND  = {CS_N,RAS_N,CAS_N,WE_N}
    output  reg     [11:0]  INIT_A_ADDR   ,
    output  reg     [ 1:0]  INIT_BANK_ADDR,
    output  reg             INIT_DONE
);
    `include "D:/three_verilog/SDRAM/SDRAM_init/rtl/sdram_param.h"
    localparam TIME_TO_PRE   = TIME_WAIT_ABOVE_100US;
    localparam TIME_TO_ARF   = TIME_WAIT_ABOVE_100US + TIME_PRE_CHARGE;
    localparam TIME_TO_ARF_2 = TIME_WAIT_ABOVE_100US + TIME_PRE_CHARGE 
                             + TIME_Auto_refresh;
    localparam TIME_TO_MRS   = TIME_WAIT_ABOVE_100US + TIME_PRE_CHARGE 
                             + TIME_Auto_refresh + TIME_Auto_refresh;
    localparam INIT_END      = TIME_TO_MRS + TIME_MRS_done_wait     ;

            reg     [13:0]  INIT_CNT     ;
            reg             INIT_DONE_NOW;
            
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            INIT_DONE <= 'd0;
        end else if(INIT_CNT == INIT_END) begin
            INIT_DONE <= 'd1;
        end else begin
            INIT_DONE <= 'd0;
        end
    end
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            INIT_DONE_NOW <= 1'b0;
        end else if(INIT_CNT == INIT_END) begin
            INIT_DONE_NOW <= 1'b1;
        end else begin
            INIT_DONE_NOW <= INIT_DONE_NOW;
        end
    end
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            INIT_CNT <= 'd0;
        end else if(INIT_DONE_NOW == 1'b0) begin
            if(INIT_CNT == INIT_END) begin
                INIT_CNT <= 'd0;
            end else begin
                INIT_CNT <= INIT_CNT + 1'b1;
            end
        end else begin
            INIT_CNT <= 'd0;
        end
    end
    always @(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            COMMAND_INIT   <= COMMAND_NOP;
            INIT_A_ADDR    <= 12'd0      ;
            INIT_BANK_ADDR <= 2'b00      ;
        end else begin
            case (INIT_CNT)
                TIME_TO_PRE: begin
                    COMMAND_INIT      <= COMMAND_PRE;
                    INIT_A_ADDR[10]   <= 1'b1;
                end
                TIME_TO_ARF: begin
                    COMMAND_INIT <= COMMAND_ARF;
                end
                TIME_TO_ARF_2: begin
                    COMMAND_INIT <= COMMAND_ARF;
                end
                TIME_TO_MRS: begin
                    COMMAND_INIT <= COMMAND_MRS;
                    INIT_A_ADDR       <= {
                        2'b00                   ,//A11 A10
                        INIT_OPMODE_Brust_Mode  ,//A9
                        INIT_OPMODE_STANDRD     ,//A8 A7
                        INIT_OPMODE_CL          ,//A6 A5 A4 ;CAS Latency ( 2 & 3 ) 
                        INIT_Burst_type         ,//A3 0:Sequential 1:Interleave          
                        INIT_OPMODE_Brust_Length //A2 A1 A0 ;Burst Length ( 1, 2, 4, 8 & full page )
                    };
                end
                default:begin
                    COMMAND_INIT   <= COMMAND_NOP;
                    INIT_A_ADDR    <= 12'd0      ;
                    INIT_BANK_ADDR <= 2'b00		;
                end
            endcase
        end
	end
endmodule
