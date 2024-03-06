module vga_ctrl #(
    parameter   H_Sync       = 96,
    parameter   H_backporch  = 40 ,
    parameter   H_left       = 8  ,
    parameter   H_data       = 640,
    parameter   H_right      = 8  ,
    parameter   H_Frontporch = 8  ,
    parameter   H_total      = H_Sync + H_backporch + H_left + H_data + H_right + H_Frontporch,
    parameter   H_width      = $clog2(H_total),
    parameter   V_Sync       = 2,
    parameter   V_backporch  = 25 ,
    parameter   V_left       = 8  ,
    parameter   V_data       = 480,
    parameter   V_right      = 8  ,
    parameter   V_Frontporch = 2  ,
    parameter   V_total      = V_Sync + V_backporch + V_left + V_data + V_right + V_Frontporch,
    parameter   V_width      = $clog2(V_total),
    parameter   RGB_width    = 8,
    //color
    parameter RED   = 8'b111_000_00,
    parameter GRENN = 8'b000_111_00,
    parameter BLUE  = 8'b000_000_11
)(
    input   wire                        Sys_clk      ,
    input   wire                        Rst_n        ,
    // input   wire    [RGB_width-1:0]     RGB_IN       , 
    output  wire    [2:0]               red_sign     ,
    output  wire    [2:0]               grenn_sign   ,
    output  wire    [1:0]               blue_sign    ,
    output  reg                         H_Sync_sign  ,
    output  reg                         V_Sync_sign  ,
    output  wire    [H_width-1:0]       H_addr       ,
    output  wire    [V_width-1:0]       V_addr       ,
    //SDARM_RD
    output  wire                        SDRAM_FIFO_RD_EN,
    input   wire    [RGB_width-1:0]     SDRAM_FIFO_RD_DATA
);
    localparam white = 8'b111_111_11;
    localparam black = 8'b000_000_00;
            wire    [7:0]           rgb   ;
            reg     [H_width-1:0]   H_cnt ;
            reg                     H_full;
            reg     [V_width-1:0]   V_cnt ;
            reg                     V_full;
            wire                    Pixl_avai;
        //background
            reg     [7:0]           backgroud_color;
//Sync
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 0) begin
            H_Sync_sign <= 1'b1;
        end else if(H_cnt == H_total - 1'b1) begin
            H_Sync_sign <= 1'b1;
        end else if(H_cnt == H_Sync -1'b1) begin
            H_Sync_sign <= 1'b0;
        end
    end
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 0) begin
            V_Sync_sign <= 1'b1;
        end else if((V_cnt == V_total - 1'b1) && (H_cnt == H_total - 1'b1)) begin
            V_Sync_sign <= 1'b1;
        end else if((V_cnt == V_Sync  - 1'b1) && (H_cnt == H_total - 1'b1)) begin
            V_Sync_sign <= 1'b0;
        end
    end
//backgroud_color
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 0) begin
            backgroud_color <= white;
        end else if(V_addr >= 0 && V_addr <= 159) begin
            backgroud_color <= RED;
        end else if(V_addr >= 160 && V_addr <= 319) begin
            backgroud_color <= GRENN;
        end else if(V_addr >= 320 && V_addr <= 479) begin
            backgroud_color <= BLUE;
        end else begin
            backgroud_color <= white;
        end
    end
//addr
    assign H_addr    =  (Pixl_avai)?(H_cnt - (H_Sync + H_backporch +  H_left)):10'd0;
    assign V_addr    =  (Pixl_avai)?(V_cnt - (V_Sync + V_backporch +  V_left)):10'd0;
//pixl_able
    assign Pixl_avai = (H_cnt >  (H_Sync + H_backporch  + H_left  -1'b1 ))
                    && (H_cnt <= (H_total- H_Frontporch - H_right -1'b1 )) 
                    && (V_cnt >  (V_Sync + V_backporch +  V_left  -1'b1 ))
                    && (V_cnt <= (V_total- V_Frontporch - V_right -1'b1 ));
//SDRAM_FIFO_RD_EN
    assign SDRAM_FIFO_RD_EN = Pixl_avai;
//RGB
    assign {red_sign,grenn_sign,blue_sign} = (Pixl_avai) ? rgb : 8'd0;
    assign rgb = (Pixl_avai)?(SDRAM_FIFO_RD_DATA):(backgroud_color);
//CNT_H_V
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 0) begin
            H_cnt <= 0;
        end else if(H_cnt == H_total - 1'b1) begin
            H_cnt <= 0;
        end else begin
            H_cnt <= H_cnt + 1'b1;
        end
    end
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 0) begin
            H_full <= 1'b0;
        end else if(H_cnt == H_total - 1'b1) begin
            H_full <= 1'b1;
        end else begin
            H_full <= 1'b0;
        end
    end
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 0) begin
            V_cnt <= 0;
        end else if((V_cnt == V_total - 1'b1) && (H_cnt == H_total - 1'b1)) begin
            V_cnt <= 0;
        end else if(H_cnt == H_total - 1'b1) begin
            V_cnt <= V_cnt + 1'b1;
        end else begin
            V_cnt <= V_cnt;
        end
    end
    always@(posedge Sys_clk or negedge Rst_n) begin
        if(Rst_n == 0) begin
            V_full <= 1'b0;
        end else if((V_cnt == V_total - 1'b1) && (H_cnt == H_total - 1'b1)) begin
            V_full <= 1'b1;
        end else begin
            V_full <= 1'b0;
        end
    end
endmodule