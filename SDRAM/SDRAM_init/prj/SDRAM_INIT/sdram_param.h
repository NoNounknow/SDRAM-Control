//COMMAND  = {CS_N,RAS_N,CAS_N,WE_N};
parameter  COMMAND_MRS          = 4'b0000 ;
parameter  COMMAND_ARF          = 4'b0001 ;
parameter  COMMAND_PRE          = 4'b0010 ;
parameter  COMMAND_BA           = 4'b0011 ;
parameter  COMMAND_WRITE        = 4'b0100 ;
parameter  COMMAND_READ         = 4'b0101 ;
parameter  COMMAND_interrupt    = 4'b0110 ;
parameter  COMMAND_NOP          = 4'b0111 ;

//time_wait
parameter   TIME_WAIT_ABOVE_100US = 10000 ;//wait_time > 100us set:200us
parameter   TIME_PRE_CHARGE       = 2     ;//tRP       > 18ns  set:40ns;
parameter   TIME_Auto_refresh     = 5     ;//tRFC=TRRC > 60ns  set:100ns
parameter   TIME_MRS_done_wait    = 2     ;//tMRS=2 CLK :During 2CLK following this command, the SDRAM cannot accept any other commands. 

//MRS_OPCODE
parameter INIT_OPMODE_Brust_Mode   = 1'b0   ;//A9
parameter INIT_OPMODE_STANDRD      = 2'b00  ;//A8 A7
parameter INIT_CAS_Latency         = 3      ;//A6 A5 A4 ;CAS Latency ( 2 & 3 ) 
parameter INIT_Burst_type          = 1'b0   ;//A3 0:Sequential 1:Interleave
parameter INIT_Burst_length        = 4      ;//A2 A1 A0 ;Burst Length ( 1, 2, 4, 8 & full page )
parameter INIT_OPMODE_Brust_Length = (INIT_Burst_length == 1)?(3'b000):
                                     (INIT_Burst_length == 2)?(3'b001):
                                     (INIT_Burst_length == 4)?(3'b010):
                                     (INIT_Burst_length == 8)?(3'b011):(3'b111);//( 1, 2, 4, 8 & full page )
parameter INIT_OPMODE_CL           = (INIT_CAS_Latency  == 2)?(3'b010):(3'b011);//A6 A5 A4 ;