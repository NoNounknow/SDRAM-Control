module SDRAM_top #(
    parameter SDRAM_DATA_WIDTH   = 16,
    parameter SDRAM_BANK_WIDTH   = 2 ,
    parameter SDRAM_ADDR_WIDTH   = 12
)(
    input   wire            Sys_clk,
    input   wire            Rst_n  ,
    //COMMAND
    output  wire            SDRAM_CS_N      ,
    output  wire            SDRAM_RAS_N     ,
    output  wire            SDRAM_CAS_N     ,
    output  wire            SDRAM_WE_N      ,
    output  wire            SDRAM_CKE       ,
    output  wire    [1:0]   SDRAM_DQM       ,
    output  wire            SDRAM_CLK       ,
    //ADDR  
    output  wire    [SDRAM_ADDR_WIDTH-1:0]  SDRAM_A_ADDR    ,
    output  wire    [SDRAM_BANK_WIDTH-1:0]  SDRAM_BANK_ADDR ,
    //DATA
    inout           [SDRAM_DATA_WIDTH-1:0]  SDRAM_DQ        
);
/*-------------------instance begin---------------------------*/
SDRAM_INIT  INST0_SDRAM_INIT(
//input
    .Sys_clk                 ( Sys_clk         ),
    .Rst_n                   ( Rst_n           ),
//output
    .COMMAND_INIT            ({ SDRAM_CS_N,
                                SDRAM_RAS_N,
                                SDRAM_CAS_N,
                                SDRAM_WE_N }),
    .INIT_A_ADDR             ( SDRAM_A_ADDR    ),
    .INIT_BANK_ADDR          ( SDRAM_BANK_ADDR ),
    .INIT_DONE               ( INIT_DONE       )
);
/*-------------------instance end-----------------------------*/
    assign  SDRAM_DQM = 2'b00;
    assign  SDRAM_CKE = 1'b1 ;
    assign  SDRAM_CLK = Sys_clk;

endmodule
