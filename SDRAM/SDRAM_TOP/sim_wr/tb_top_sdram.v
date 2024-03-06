`timescale 1ns/1ns
`define clock_period 20
module tb_top_sdram;
// SDRAM_top Inputs
    reg   Sys_clk  ;
    reg   Rst_n    ;

// SDRAM_top Outputs
    wire          SDRAM_CS_N        ;
    wire          SDRAM_RAS_N       ;
    wire          SDRAM_CAS_N       ;
    wire          SDRAM_WE_N        ;
    wire          SDRAM_CKE         ;
    wire  [ 1:0]  SDRAM_DQM         ;
    wire          SDRAM_CLK         ;
    wire  [11:0]  SDRAM_A_ADDR      ;
    wire  [ 1:0]  SDRAM_BANK_ADDR   ;
//SDRAM_WR_EN;
    reg           SDRAM_WR_FIFO_WR_EN;
    reg   [ 7:0]  SDRAM_WR_FIFO_DATA ;

//SDRAM_top Bidirs
    wire  [15:0]  SDRAM_DQ     ;
//SDRAM_INIT_DONE
    wire          SDRAM_INIT_DONE;
/*-------------------instance begin---------------------------*/
SDRAM_top INST0_SDRAM_top(
    .Sys_clk                 ( Sys_clk         ),
    .Rst_n                   ( Rst_n           ),

    .SDRAM_CS_N              ( SDRAM_CS_N      ),
    .SDRAM_RAS_N             ( SDRAM_RAS_N     ),
    .SDRAM_CAS_N             ( SDRAM_CAS_N     ),   
    .SDRAM_WE_N              ( SDRAM_WE_N      ),
    .SDRAM_CKE               ( SDRAM_CKE       ),
    .SDRAM_DQM               ( SDRAM_DQM       ),
    .SDRAM_CLK               ( SDRAM_CLK       ),
    .SDRAM_A_ADDR            ( SDRAM_A_ADDR    ),
    .SDRAM_BANK_ADDR         ( SDRAM_BANK_ADDR ),

    .SDRAM_DQ                ( SDRAM_DQ        )
);
sdram_model_plus INST0_sdram_model_plus(
    .Addr                    ( SDRAM_A_ADDR    ),
    .Ba                      ( SDRAM_BANK_ADDR ),
    .Clk                     ( SDRAM_CLK       ),
    .Cke                     ( SDRAM_CKE       ),
    .Cs_n                    ( SDRAM_CS_N      ),
    .Ras_n                   ( SDRAM_RAS_N     ),
    .Cas_n                   ( SDRAM_CAS_N     ),
    .We_n                    ( SDRAM_WE_N      ),
    .Dqm                     ( SDRAM_DQM       ),
    .Debug                   ( 1'b1            ),

    .Dq                      ( SDRAM_DQ        )
);
/*-------------------instance end-----------------------------*/
initial Sys_clk = 0;
always #(`clock_period/2) Sys_clk = ~  Sys_clk;

initial begin
    Rst_n = 1'b0;
    SDRAM_WR_FIFO_WR_EN = 1'b0;
    SDRAM_WR_FIFO_DATA  = 8'd0;
    repeat(10) @(posedge Sys_clk);
    Rst_n = 1'b1;
    repeat(1 ) @(posedge Sys_clk);
    Gen_FIFO_WR_data;
end

initial begin
    force INST0_SDRAM_top.INST0_SDRAM_CTRL_TOP.INST0_SDRAM_WR.FIFO_WR_EN   = SDRAM_WR_FIFO_WR_EN  ;
    force INST0_SDRAM_top.INST0_SDRAM_CTRL_TOP.INST0_SDRAM_WR.FIFO_WR_data = SDRAM_WR_FIFO_DATA   ;
    force SDRAM_INIT_DONE = INST0_SDRAM_top.INST0_SDRAM_CTRL_TOP.INIT_DONE;
end

task Gen_FIFO_WR_data();
        integer i;
        integer j;
            begin
                @(posedge SDRAM_INIT_DONE);
                repeat(5) @(posedge Sys_clk);
                for (i=0;i<480;i=i+1) begin
                    for(j=0;j<640;j=j+1) begin
                        @(posedge Sys_clk);
                        SDRAM_WR_FIFO_WR_EN = 1'b1;
                        SDRAM_WR_FIFO_DATA  = j[7:0];
                    end
                    @(posedge Sys_clk);
                    SDRAM_WR_FIFO_WR_EN = 1'b0;
                    repeat(1000) @(posedge Sys_clk);
                end
            end
endtask
endmodule //tb_top_sdram