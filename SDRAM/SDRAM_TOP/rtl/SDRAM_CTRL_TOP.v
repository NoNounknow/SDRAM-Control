module SDRAM_CTRL_TOP #(
    parameter SDRAM_DATA_WIDTH   = 16,
    parameter SDRAM_BANK_WIDTH   = 2 ,
    parameter SDRAM_ADDR_WIDTH   = 12
)(
    input   wire         Sys_clk,
    input   wire         Rst_n  ,
//PLL
    input   wire            VGA_CLOCK       ,//25MHZ = 800X525X60 
//SDRAM 
    //COMMAND
    output  wire            SDRAM_CS_N                      ,
    output  wire            SDRAM_RAS_N                     ,
    output  wire            SDRAM_CAS_N                     ,
    output  wire            SDRAM_WE_N                      ,
    output  wire            SDRAM_CKE                       ,
    output  wire    [1:0]   SDRAM_DQM                       ,
    output  wire            SDRAM_CLK                       ,
    output  reg     [SDRAM_ADDR_WIDTH-1:0]  SDRAM_A_ADDR    ,
    output  reg     [SDRAM_BANK_WIDTH-1:0]  SDRAM_BANK_ADDR ,
    //WR_FIFO
    input   wire            FIFO_WR_EN                      ,
    input   wire    [7:0]   FIFO_WR_data                    ,
    //DATA
    inout           [SDRAM_DATA_WIDTH-1:0]  SDRAM_DQ        ,
    //VGA
    output  wire    [2:0]   red_sign                        ,
    output  wire    [2:0]   grenn_sign                      ,
    output  wire    [1:0]   blue_sign                       ,
    output  wire            H_Sync_sign                     ,
    output  wire            V_Sync_sign                     
);
`include "D:/three_verilog/SDRAM/SDRAM_init/rtl/sdram_param.h"
    localparam  STATE_IDLE = 6'b00_0001;
    localparam  STATE_INIT = 6'b00_0010;
    localparam  STATE_ARB  = 6'b00_0100;
    localparam  STATE_ARF  = 6'b00_1000;
    localparam  STATE_RD   = 6'b01_0000;
    localparam  STATE_WE   = 6'b10_0000;
    //Main
            reg  [3:0]                    SDRAM_COMMAND_SEND;
            reg  [5:0]                    STATE             ;
           wire                           WR_avai           ;
           wire  [SDRAM_DATA_WIDTH-1:0]   WR_SDRAM_DQ       ;
           reg   [SDRAM_DATA_WIDTH-1:0]   READ_SDRAM_DQ     ;
    //init
           wire                           INIT_DONE         ;
           wire  [3:0]                    COMMAND_INIT      ;       
           wire  [SDRAM_ADDR_WIDTH-1:0]   INIT_A_ADDR       ;
           wire  [SDRAM_BANK_WIDTH-1:0]   INIT_BANK_ADDR    ;
    //ARF
           wire                           ARF_access        ;
           wire  [3:0]                    COMMAND_REF       ;
           wire  [SDRAM_ADDR_WIDTH-1:0]   ARF_A_ADDR        ;
           wire  [SDRAM_BANK_WIDTH-1:0]   ARF_BANK_ADDR     ;
           wire                           REF_DONE          ;
           wire                           ARF_req           ;
    //WR
           wire                           WR_req            ;
           wire                           WR_access         ;
           wire  [3:0]                    COMMAND_RD        ;
           wire  [SDRAM_ADDR_WIDTH-1:0]   RD_A_ADDR         ;
           wire  [SDRAM_BANK_WIDTH-1:0]   RD_BANK_ADDR      ;
           wire                           WR_data_done      ;
    //RD
           wire                           RD_req            ;
           wire                           RD_access         ;
           wire                           RD_DATA_DONE      ;
           wire  [3:0]                    COMMAND_WR        ;
           wire  [SDRAM_ADDR_WIDTH-1:0]   WR_A_ADDR         ;
           wire  [SDRAM_BANK_WIDTH-1:0]   WR_BANK_ADDR      ;
    //VGA
           wire                           VGA_START         ;
           wire                           VGA_FIFO_RD_EN    ;
           wire  [7:0]                    VGA_FIFO_RD_DATA  ;
           wire  [9:0]                    H_addr            ;
           wire  [9:0]                    V_addr            ;
    //break
           wire                           Break_WR_to_ARF   ;
           wire                           Break_RD_other    ;
//DQ
    assign  WR_avai   = (STATE == STATE_WE)?1'b1:1'b0;
    always@(posedge Sys_clk) begin
        READ_SDRAM_DQ <= SDRAM_DQ;
    end
    assign  SDRAM_DQ  = (WR_avai == 1'b1)?WR_SDRAM_DQ :16'dz;
    assign  SDRAM_DQM = 2'b00  ;
    assign  SDRAM_CKE = 1'b1   ;
    assign  SDRAM_CLK = Sys_clk;
//COMMAND
    assign  {SDRAM_CS_N,
             SDRAM_RAS_N,
             SDRAM_CAS_N,
             SDRAM_WE_N } = SDRAM_COMMAND_SEND;
    always@(*) begin
        if(STATE == STATE_INIT) begin
            SDRAM_COMMAND_SEND <= COMMAND_INIT  ;
            SDRAM_A_ADDR       <= INIT_A_ADDR   ;
            SDRAM_BANK_ADDR    <= INIT_BANK_ADDR;
        end else if(STATE == STATE_ARF) begin
            SDRAM_COMMAND_SEND <= COMMAND_REF   ;
            SDRAM_A_ADDR       <= ARF_A_ADDR    ;
            SDRAM_BANK_ADDR    <= ARF_BANK_ADDR ;
        end else if(STATE == STATE_WE) begin
            SDRAM_COMMAND_SEND <= COMMAND_WR    ;
            SDRAM_A_ADDR       <= WR_A_ADDR     ;
            SDRAM_BANK_ADDR    <= WR_BANK_ADDR  ;
        end else if(STATE == STATE_RD) begin
            SDRAM_COMMAND_SEND <= COMMAND_RD    ;
            SDRAM_A_ADDR       <= RD_A_ADDR     ;
            SDRAM_BANK_ADDR    <= RD_BANK_ADDR  ;
        end else begin
            SDRAM_COMMAND_SEND <= COMMAND_NOP   ;
            SDRAM_A_ADDR       <= 'd0           ;
            SDRAM_BANK_ADDR    <= 'd0           ;
        end
    end
    //access
    assign ARF_access = (STATE == STATE_ARB) && (ARF_req == 1'b1);
    assign WR_access  = (STATE == STATE_ARB) && (WR_req  == 1'b1) 
                     && (ARF_req == 1'b0);
    assign RD_access  = (STATE == STATE_ARB) && (RD_req  == 1'b1) 
                     && (WR_req  == 1'b0   ) && (ARF_req == 1'b0);
//-------------------STATE MAIN-----------------------//
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 'd0) begin
            STATE <= STATE_IDLE;
        end else begin
            case (STATE) //ARG > WR > RD
                STATE_IDLE: begin
                    STATE <= STATE_INIT;
                end
                STATE_INIT: begin
                    if(INIT_DONE == 'd1) begin
                        STATE <= STATE_ARB;
                    end else begin
                        STATE <= STATE_INIT;
                    end
                end
                STATE_ARB: begin
                    if(ARF_req == 1'b1) begin
                        STATE <= STATE_ARF;
                    end else if(WR_req == 1'b1 && ARF_req == 1'b0) begin
                        STATE <= STATE_WE;
                    end else if(RD_req == 1'b1 && WR_req == 1'b0 && ARF_req == 1'b0) begin
                        STATE <= STATE_RD;
                    end else begin
                        STATE <= STATE_ARB;
                    end
                end
                STATE_ARF: begin
                    if(REF_DONE == 1'b1) begin
                        STATE <= STATE_ARB;
                    end else begin
                        STATE <= STATE_ARF;
                    end
                end
                STATE_WE: begin
                    if(Break_WR_to_ARF == 1'b1) begin
                        STATE <= STATE_ARB;
                    end else if(WR_data_done == 1'b1) begin
                        STATE <= STATE_ARB;
                    end else begin
                        STATE <= STATE_WE;
                    end
                end
                STATE_RD: begin
                    if(RD_DATA_DONE == 1'b1) begin
                        STATE <= STATE_ARB;
                    end else if(Break_RD_other == 1'b1) begin
                        STATE <= STATE_ARB;
                    end else begin
                        STATE <= STATE_RD;
                    end
                end
                default: begin
                    STATE <= STATE_IDLE;
                end
            endcase
        end
    end
//-------------------STATE END------------------------//

/*-------------------instance begin---------------------------*/
SDRAM_INIT  INST0_SDRAM_INIT(
//input
    .Sys_clk                 ( Sys_clk         ),
    .Rst_n                   ( Rst_n           ),
//output
    .COMMAND_INIT            ( COMMAND_INIT    ),
    .INIT_A_ADDR             ( INIT_A_ADDR     ),
    .INIT_BANK_ADDR          ( INIT_BANK_ADDR  ),
    .INIT_DONE               ( INIT_DONE       )
);
SDRAM_ARF  INST0_SDRAM_ARF (
    .Sys_clk                 ( Sys_clk               ),
    .Rst_n                   ( Rst_n                 ),
    .INIT_DONE               ( INIT_DONE             ),
    .ARF_access              ( ARF_access            ),

    .COMMAND_REF             ( COMMAND_REF           ),
    .ARF_A_ADDR              ( ARF_A_ADDR            ),
    .ARF_BANK_ADDR           ( ARF_BANK_ADDR         ),
    .REF_DONE                ( REF_DONE              ),
    .ARF_req                 ( ARF_req               )
);
SDRAM_WR INST0_SDRAM_WR(
    .Sys_clk                 ( Sys_clk               ),
    .Rst_n                   ( Rst_n                 ),
    .FIFO_WR_EN              ( FIFO_WR_EN            ),
    .FIFO_WR_data            ( FIFO_WR_data          ),
    .INIT_DONE               ( INIT_DONE             ),
    .ARF_req                 ( ARF_req               ),
    .WR_access               ( WR_access             ),

    .COMMAND_WR              ( COMMAND_WR            ),
    .WR_A_ADDR               ( WR_A_ADDR             ),
    .WR_BANK_ADDR            ( WR_BANK_ADDR          ),
    .WR_data_done            ( WR_data_done          ),
    .WR_req                  ( WR_req                ),
    .Break_WR_to_ARF         ( Break_WR_to_ARF       ),
    .WRITE_SDRAM_DQ          ( WR_SDRAM_DQ           )
);
SDRAM_RD INST0_SDRAM_RD(
    .Sys_clk                 ( Sys_clk               ),
    .Rst_n                   ( Rst_n                 ),
    .VGA_CLOCK               ( VGA_CLOCK             ),
    .VGA_FIFO_RD_EN          ( VGA_FIFO_RD_EN        ),
    .INIT_DONE               ( INIT_DONE             ),
    .WR_req                  ( WR_req                ),
    .ARF_req                 ( ARF_req               ),
    .RD_access               ( RD_access             ),
    .READ_SDRAM_DQ           ( READ_SDRAM_DQ         ),
    .WR_data_done            ( WR_data_done          ),

    .VGA_START               ( VGA_START             ),
    .VGA_FIFO_RD_DATA        ( VGA_FIFO_RD_DATA      ),
    .COMMAND_RD              ( COMMAND_RD            ),
    .RD_A_ADDR               ( RD_A_ADDR             ),
    .RD_BANK_ADDR            ( RD_BANK_ADDR          ),
    .RD_DATA_DONE            ( RD_DATA_DONE          ),
    .RD_req                  ( RD_req                ),
    .Break_RD_other          ( Break_RD_other        )
);
vga_ctrl INST0_vga_ctrl(
    .Sys_clk                 ( VGA_CLOCK             ),
    .Rst_n                   ( VGA_START             ),
    .SDRAM_FIFO_RD_DATA      ( VGA_FIFO_RD_DATA      ),
     
    .red_sign                ( red_sign              ),
    .grenn_sign              ( grenn_sign            ),
    .blue_sign               ( blue_sign             ),
    .H_Sync_sign             ( H_Sync_sign           ),
    .V_Sync_sign             ( V_Sync_sign           ),
    .H_addr                  ( H_addr                ),
    .V_addr                  ( V_addr                ),
    .SDRAM_FIFO_RD_EN        ( VGA_FIFO_RD_EN        )
);
/*-------------------instance end-----------------------------*/
endmodule
