module SDRAM_top #(
        parameter SDRAM_DATA_WIDTH   = 16,
        parameter SDRAM_BANK_WIDTH   = 2 ,
        parameter SDRAM_ADDR_WIDTH   = 12
    )(
        input   wire            Sys_clk,
        input   wire            Rst_n  ,
        //Uart
        input   wire            rx              ,
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
        inout           [SDRAM_DATA_WIDTH-1:0]  SDRAM_DQ,
        //VGA
        output  wire    [2:0]   red_sign       ,
        output  wire    [2:0]   grenn_sign     ,
        output  wire    [1:0]   blue_sign      ,
        output  wire            H_Sync_sign    ,
        output  wire            V_Sync_sign
    );
    //PLL
    wire    VGA_CLOCK   ;
    wire    CLOCK_50MHZ ;
    wire    FIFO_WR_EN  ;
    wire    FIFO_WR_data;    
    /*-------------------instance begin---------------------------*/
    SDRAM_CTRL_TOP INST0_SDRAM_CTRL_TOP (
                       .Sys_clk                 ( CLOCK_50MHZ    ),
                       .Rst_n                   ( Rst_n          ),
                       .VGA_CLOCK               ( VGA_CLOCK      ),

                       .SDRAM_CS_N              ( SDRAM_CS_N     ),
                       .SDRAM_RAS_N             ( SDRAM_RAS_N    ),
                       .SDRAM_CAS_N             ( SDRAM_CAS_N    ),
                       .SDRAM_WE_N              ( SDRAM_WE_N     ),
                       .SDRAM_CKE               ( SDRAM_CKE      ),
                       .SDRAM_DQM               ( SDRAM_DQM      ),
                       .SDRAM_CLK               ( SDRAM_CLK      ),
                       .SDRAM_A_ADDR            ( SDRAM_A_ADDR   ),
                       .SDRAM_BANK_ADDR         ( SDRAM_BANK_ADDR),
                       .FIFO_WR_EN              ( FIFO_WR_EN     ),
                       .FIFO_WR_data            ( FIFO_WR_data   ),
                       .red_sign                ( red_sign       ),
                       .grenn_sign              ( grenn_sign     ),
                       .blue_sign               ( blue_sign      ),
                       .H_Sync_sign             ( H_Sync_sign    ),
                       .V_Sync_sign             ( V_Sync_sign    ),

                       .SDRAM_DQ                ( SDRAM_DQ       )
                   );
    rx_teach rx_teach_inst0(
                    .Sys_clk                 ( CLOCK_50MHZ       ),
                    .Rst_n                   ( Rst_n             ),
                    .data_in                 ( rx                ),

                    .data_receive            ( FIFO_WR_data      ),
                    .rx_done                 ( FIFO_WR_EN        )
                    );

    PLL_base50mhz_25mhz INST0_PLL_base50mhz_25mhz
                        (// Clock in ports
                            .CLK_IN1        ( Sys_clk     ),      // IN
                            // Clock out ports
                            .CLOCK_50MHZ    ( CLOCK_50MHZ ),     // OUT
                            .CLOCK_25MHZ    ( VGA_CLOCK)  );    // OUT
    /*-------------------instance end-----------------------------*/
endmodule
