/*******************************************************************************************
* Company: 
* Engineer: helrori2011@gmail.com
* 
* Create Date: 2019/02/16 09:50:27
* Design Name: ddr3_core_alignv.v    MIG ddr3 native IF warpper ,address and data alignment
* Module Name: ddr3_core_alignv
* Project Name: 
* Target Devices: xilinx family
* Tool Versions: 
* Description: Xilinx MIG(4:1) warpper.Compatible with ddr3_core.v port(BUT ddr3_core_alignv's 
*              wr_data NEED PRE-FETCH),ddr3_core_alignv.v : write address and data alignment,
*              wr_data pre-fetch need!
*              1.   test ok for single ddr3 16bitx128=2Gibit,xilinx MIG(400Mhz:100Mhz) 
*                   100Mhzx128bit app input;
*              2.   test ok for 2GB SODIMM,xilinx MIG(400Mhz:100Mhz)100Mhzx512bit app input;
*
*              define _NOMIG_DEBUG_ to enable 'no mig debug mode'
*              define _MIG_EX_DSCLK_ to use external DS clock,single port clk used by default
* Dependencies: This module contains a Xilinx MIG IP.
* 
* Revision:
* Revision 0.01 - File Created
* Additional Comments:GB2312
********************************************************************************************/
`timescale 1ns / 1ps
module ddr3_core_alignv
#(
//--------------------------------------------------------------------------------
    parameter APP_DATA_WIDTH = 128  ,
	parameter APP_ADDR_WIDTH = 28   ,

    parameter DQW            = 16   ,
    parameter DQSW           = 2    ,
    parameter ADDRW          = 14   ,
    parameter BAW            = 3    ,
    parameter DMW            = 2
//--------------------------------------------------------------------------------
)
(
    //CLOCK
`ifdef _MIG_EX_DSCLK_
    input     wire  sys_clk_p,
    input     wire  sys_clk_n,
`else
    input     wire  clk_200Mhz  ,               //PLL-->MIG
`endif
    input     wire  rst_n,                      //   -->MIG
    //HOST
`ifdef _NOMIG_DEBUG_
    output    reg   clk,                        //MIG-->user
    output    reg   rst,                        //MIG-->user
`else
    output    wire  clk,                        //MIG-->user
    output    wire  rst,                        //MIG-->user
`endif
    input     wire                      wr_request,//|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    input     wire  [APP_ADDR_WIDTH-1:0]wr_addr,   //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//{rank,bank[2:0],row[13:0],col[9:0]}
    input     wire  [9    :0]           wr_num,    //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//pls  > 0 & < 1024 ,wr_num==1 suggest write 1x8xDQW bits
    input     wire  [APP_DATA_WIDTH-1:0]wr_data,   //XXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXXXXXX//wr_data pre-fetch need!!
    output    wire                      wr_allow,  //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|________//
    output    wire                      wr_finish, //___________________________________________|~~|__//
    output    wire                      wr_busy,   //|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|__//
    
    input     wire                      rd_request,//|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    input     wire  [APP_ADDR_WIDTH-1:0]rd_addr,   //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//{rank,bank[2:0],row[13:0],col[9:0]}
    input     wire  [9    :0]           rd_num,    //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//pls  > 0 & < 1024 ,wr_num==1 suggest read 1x8xDQW bits
    output    wire  [APP_DATA_WIDTH-1:0]rd_data,   //XXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXXXXXX//
    output    wire                      rd_allow,  //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|________//
    output    wire                      rd_finish, //___________________________________________|~~|__//
    output    wire                      rd_busy,   //|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|__//
    
    output    wire                  init_calib_complete,
    //DDR3 PIN
    inout     wire   [DQW-1:0]      ddr3_dq,
    inout     wire   [DQSW-1:0]     ddr3_dqs_n,
    inout     wire   [DQSW-1:0]     ddr3_dqs_p,
    output    wire   [ADDRW-1:0]    ddr3_addr,
    output    wire   [BAW-1:0]      ddr3_ba,
    output    wire                  ddr3_ras_n,
    output    wire                  ddr3_cas_n,
    output    wire                  ddr3_we_n,
    output    wire                  ddr3_reset_n,
    output    wire   [0:0]          ddr3_ck_p,
    output    wire   [0:0]          ddr3_ck_n,
    output    wire   [0:0]          ddr3_cke,
    output    wire   [0:0]          ddr3_cs_n,
    output    wire   [DMW-1:0]      ddr3_dm,
    output    wire   [0:0]          ddr3_odt
);
localparam  APP_CMD_WR = 3'd0,
            APP_CMD_RD = 3'd1;

reg    [APP_ADDR_WIDTH-1:0]  app_addr;//{rank,bank[2:0],row[13:0],col[9:0]},2^27 == 8 banks * 2^14 row * 2^10 col
reg    [2:0]                 app_cmd;
reg                          app_en;
wire   [APP_DATA_WIDTH-1:0]  app_wdf_data;
wire                         app_wdf_end;
wire   [APP_DATA_WIDTH/8-1:0]app_wdf_mask = {APP_DATA_WIDTH/8{1'b0}};
wire                         app_wdf_wren;
wire   [APP_DATA_WIDTH-1:0]  app_rd_data;
wire                         app_rd_data_end;//not use

wire                         app_sr_active; //not use
wire                         app_ref_ack;   //not use
wire                         app_zq_ack;    //not use


reg    [APP_ADDR_WIDTH-1:0]rd_addr_b,wr_addr_b;
reg    [9:0]rd_num_b,wr_num_b;
reg    rd_request_b,wr_request_b;

`ifdef _NOMIG_DEBUG_ 
    reg     [27:0]               addr2xilinx_ip = 28'd0;
    reg     [APP_DATA_WIDTH-1:0] data2xilinx_ip = 'd0;
    reg                          app_rd_data_valid = 0;
    reg                          init_calib_complete_b = 0;
    integer i = 0;
    assign                       init_calib_complete = init_calib_complete_b;
    reg                          app_rdy;
    always              begin    #(5.0) clk <= ~clk;end
    always@(posedge clk)begin    app_rdy = 1;/*$random(i) % 2;*/end//It is necessary to set it to other values to see different situations
    wire                         app_wdf_rdy = 1;//caution!          It is necessary to set it to other values to see different situations
    reg                     [9:0]cnt1 = 9'd0;
    reg                          rd_request_bb = 0;
    initial begin
        clk = 1;
        rst = 0;
        #(30) rst      = 1;
        #(30) rst      = 0;
        #(100) init_calib_complete_b = 1;
    end
    always@(posedge clk)begin
        if(rd_finish)begin
            rd_request_bb <=  1'd0;
        end else if(rd_request)
            rd_request_bb <=  1'd1;
            
        if(rd_finish)begin
            cnt1 <=  'd0;     
        end else if(rd_request_bb && app_cmd == APP_CMD_RD)
            cnt1 <=  cnt1 + 1'd1;
        app_rd_data_valid <= (cnt1>10'd2&&cnt1<=(10'd2+rd_num_b));
    end
    /*
        When the user logic app_en signal is asserted and the app_rdy signal is asserted from the 
        UI, a command is accepted and written to the FIFO by the UI. The command is ignored by 
        the UI whenever app_rdy is deasserted. The user logic needs to hold app_en High along 
        with the valid command and address values until app_rdy is asserted
    */
    always@(posedge clk)begin 
        if(app_rdy&&app_en)//MIG IP ADDR INPUT TEST
            addr2xilinx_ip <= app_addr;  
        if(app_rdy&&app_wdf_rdy&&app_en&&app_wdf_wren)//MIG IP DATA INPUT TEST
            data2xilinx_ip <= app_wdf_data;  
    end
`else
    wire                         app_rd_data_valid;
    wire                         app_rdy;
    wire                         app_wdf_rdy;
`endif

assign app_wdf_wren = app_en & app_rdy & app_wdf_rdy & (app_cmd == APP_CMD_WR);// - 190216 
assign app_wdf_end  = app_wdf_wren;
assign app_wdf_data = wr_data;

assign wr_allow     = app_wdf_wren; 
assign rd_data      = app_rd_data;
assign rd_allow     = app_rd_data_valid;
assign wr_busy      = wr_request_b;
assign rd_busy      = rd_request_b;
/*******************************************************************************************
*   state machine
********************************************************************************************/
localparam  IDLE             = 3'd0,
            WR_ADDR_AND_DATA = 3'd1,
            WR_FINISH        = 3'd2,
            RD_ADDR_AND_DATA = 3'd3,
            RD_REST          = 3'd4,
            RD_FINISH        = 3'd5;            
reg [2:0]   state;
reg [9:0]   rd_addr_cnt,rd_data_cnt,wr_cnt;//1024x8 words

assign wr_finish = state == WR_FINISH;
assign rd_finish = state == RD_FINISH;

always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		state       <= IDLE       ;
		app_cmd     <= APP_CMD_WR ;
		app_addr    <= 'd0        ;
		app_en      <= 1'd0       ;
		rd_addr_cnt <= 10'd0      ;
		rd_data_cnt <= 10'd0      ;
		wr_cnt      <= 10'd0      ;
	end
	else if(init_calib_complete ===  1'b1)
	begin
		case(state)
			IDLE:begin
				if(rd_request_b)begin//read request first!!
					state       <= RD_ADDR_AND_DATA;
					app_cmd     <= APP_CMD_RD      ;
					app_addr    <= rd_addr_b       ;
					app_en      <= 1'b1            ;
				end else if(wr_request_b)begin
					state       <= WR_ADDR_AND_DATA;
					app_cmd     <= APP_CMD_WR      ;
					app_addr    <= wr_addr_b       ;
					app_en      <= 1'b1            ;
                    wr_cnt      <= 10'd0           ;
				end
			end
			RD_ADDR_AND_DATA:begin
				if(app_rdy)begin
					app_addr        <= app_addr + 'd8;
					if(rd_addr_cnt == rd_num_b - 1)begin
						state       <= RD_REST;
						rd_addr_cnt <= 10'd0;
						app_en      <= 1'b0;
					end else
                        rd_addr_cnt <= rd_addr_cnt + 1'd1;
				end	
				if(app_rd_data_valid)begin
					if(rd_data_cnt == rd_num_b - 1)begin
						rd_data_cnt <= 10'd0;
						state       <= RD_FINISH;
					end else begin
						rd_data_cnt <= rd_data_cnt + 1'd1;
					end
				end
			end
			RD_REST:begin			
				if(app_rd_data_valid)begin
					if(rd_data_cnt == rd_num_b - 1)begin
						rd_data_cnt <= 10'd0;
						state       <= RD_FINISH;
					end else begin
						rd_data_cnt <= rd_data_cnt + 1'd1;
					end
				end
			end
 			RD_FINISH:state <= IDLE;
			WR_ADDR_AND_DATA:begin// - 190216 
				if(app_rdy && app_wdf_rdy)begin                   
                    if(wr_cnt == wr_num_b - 1)begin
                        wr_cnt      <= 10'd0;
                        app_en      <= 1'd0;
                        state       <= WR_FINISH;
                    end else begin
                        wr_cnt      <= wr_cnt   +   1'd1;
                        app_addr    <= app_addr +   'd8;
                    end
				end
			end
			WR_FINISH:begin
				state <= IDLE;
            end
			default:state <= IDLE;
		endcase
	end
end
/*******************************************************************************************
*   read & write request register
*******************************************************************************************/ 
always@(posedge clk or posedge rst)begin
    if(rst)begin
        rd_addr_b   <= 'd0;
        rd_num_b    <= 'd0;
        rd_request_b<= 'd0;
        wr_addr_b   <= 'd0;
        wr_num_b    <= 'd0;
        wr_request_b<= 'd0;
    end else begin
        if(state == RD_FINISH)begin     
            rd_request_b<=  1'd0;       //( - 190208)
        end else if(rd_request)begin
            rd_addr_b   <=  rd_addr;    
            rd_num_b    <=  rd_num;     
            rd_request_b<=  1'd1;              
        end else
            rd_request_b<=  rd_request_b;
            
        if(state == WR_FINISH)begin
            wr_request_b<=  1'd0;       //( - 190208)
        end else if(wr_request)begin
            wr_addr_b   <=  wr_addr;    
            wr_num_b    <=  wr_num;     
            wr_request_b<=  1'd1;               
        end else
            wr_request_b<=  wr_request_b;
    end
end

/*******************************************************************************************
*   xilinx mig(4:1) ddr3(16x128M) ip
********************************************************************************************/
`ifndef _NOMIG_DEBUG_
ddr3_ip u_ddr3_ip
(
    // System Clock Ports
`ifdef _MIG_EX_DSCLK_
    .sys_clk_p                      (sys_clk_p              ),
    .sys_clk_n                      (sys_clk_n              ),
`else
    .sys_clk_i                      (clk_200Mhz                ),
`endif
    .sys_rst                        (rst_n                  ),
    // Memory interface ports
    .ddr3_addr                      (ddr3_addr              ),
    .ddr3_ba                        (ddr3_ba                ),
    .ddr3_cas_n                     (ddr3_cas_n             ),
    .ddr3_ck_n                      (ddr3_ck_n              ),
    .ddr3_ck_p                      (ddr3_ck_p              ),
    .ddr3_cke                       (ddr3_cke               ),
    .ddr3_ras_n                     (ddr3_ras_n             ),
    .ddr3_we_n                      (ddr3_we_n              ),
    .ddr3_dq                        (ddr3_dq                ),
    .ddr3_dqs_n                     (ddr3_dqs_n             ),
    .ddr3_dqs_p                     (ddr3_dqs_p             ),
    .ddr3_reset_n                   (ddr3_reset_n           ),
    .init_calib_complete            (init_calib_complete    ),
    .ddr3_cs_n                      (ddr3_cs_n              ),
    .ddr3_dm                        (ddr3_dm                ),
    .ddr3_odt                       (ddr3_odt               ),
    // Application interface ports
    .app_addr                       (app_addr               ),
    .app_cmd                        (app_cmd                ),
    .app_en                         (app_en                 ),
    .app_wdf_data                   (app_wdf_data           ),
    .app_wdf_end                    (app_wdf_end            ),
    .app_wdf_wren                   (app_wdf_wren           ),
    .app_rd_data                    (app_rd_data            ),
    .app_rd_data_end                (app_rd_data_end        ),
    .app_rd_data_valid              (app_rd_data_valid      ),
    .app_rdy                        (app_rdy                ),
    .app_wdf_rdy                    (app_wdf_rdy            ),
    .app_wdf_mask                   (app_wdf_mask           ),
    .app_sr_req                     (1'b0                   ),
    .app_ref_req                    (1'b0                   ),
    .app_zq_req                     (1'b0                   ),
    .app_sr_active                  (app_sr_active          ),
    .app_ref_ack                    (app_ref_ack            ),
    .app_zq_ack                     (app_zq_ack             ),
    .ui_clk                         (clk                    ),//100Mhz-->user
    .ui_clk_sync_rst                (rst                    ) //      -->user  
); 
`endif
endmodule

