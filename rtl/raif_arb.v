/************************************************************************************
*   Name         :raif_arb [可以直接使用]
*   Description  :这是RAIF接口仲裁器. 它简单包装了 rdreq_sel 和 wrreq_sel.
*                 RTL结构见RAIF.vh内 . 该仲裁器，使用FIFO模式，先来先处理，处理过程中不能被
*                 其他请求抢断. 当多个请求同时到来时，按照固有优先级先后处理(通道0优先级最高)
*                 1.CHANNEL_NUM=2,SDRAM仅使用单通道读写 test ok
*                 2.CHANNEL_NUM=2,SDRAM双通道皆使用读写 test ok,140Mbytes/200Mbytes
*   Interface    :RAIF
*   Origin       :190721
*                 190723
*                 190725
*   Author       :helrori2011@gmail.com
*   Reference    :
************************************************************************************/
module raif_arb
#(
    parameter APP_DATA_WIDTH = 128  ,     
	parameter APP_ADDR_WIDTH = 28   ,
    parameter CHANNEL_NUM    = 2    ,//CHANNEL_NUM >=1
    parameter RAIFWRDATA_PREFETCH = "FALSE"
)
(
    // clock
    input       clk     ,
    input       rst_n   ,
    // RAXX_RCIF to user
    input  wire              [CHANNEL_NUM  -1:0]rd_req_      ,
    input  wire [APP_ADDR_WIDTH*CHANNEL_NUM-1:0]rd_addr_     ,
    input  wire             [10*CHANNEL_NUM-1:0]rd_num_      ,//512 >= xx_num  > 0 如果使用sdram_interface.v 建议设小
    output wire [APP_DATA_WIDTH*CHANNEL_NUM-1:0]rd_data_     ,
    output wire              [CHANNEL_NUM  -1:0]rd_grant_    ,
    output wire              [CHANNEL_NUM  -1:0]rd_finish_   ,
    input  wire              [CHANNEL_NUM  -1:0]wr_req_      ,
    input  wire [APP_ADDR_WIDTH*CHANNEL_NUM-1:0]wr_addr_     ,
    input  wire             [10*CHANNEL_NUM-1:0]wr_num_      ,//512 >= xx_num  > 0 如果使用sdram_interface.v 建议设小
    input  wire [APP_DATA_WIDTH*CHANNEL_NUM-1:0]wr_data_     ,
    input  wire [APP_DATA_WIDTH*CHANNEL_NUM/8-1:0]wr_mask_   ,
    output wire              [CHANNEL_NUM  -1:0]wr_grant_    ,
    output wire              [CHANNEL_NUM  -1:0]wr_finish_   ,
    // RAXX_TRIF to sdram_interface.v or ddr3_core.v
    output wire                      rd_req      ,
    output wire  [APP_ADDR_WIDTH-1:0]rd_addr     ,
    output wire  [9    :0]           rd_num      ,
    input  wire  [APP_DATA_WIDTH-1:0]rd_data     ,
    input  wire                      rd_grant    ,
    input  wire                      rd_finish   ,
    output wire                      wr_req      ,
    output wire  [APP_ADDR_WIDTH-1:0]wr_addr     ,
    output wire  [9    :0]           wr_num      ,
    output wire  [APP_DATA_WIDTH-1:0]wr_data     ,
    output wire[APP_DATA_WIDTH/8-1:0]wr_mask     ,
    input  wire                      wr_grant    ,
    input  wire                      wr_finish
);
generate
if (CHANNEL_NUM>1) begin
    rdreq_sel 
    #(  .APP_DATA_WIDTH(APP_DATA_WIDTH),
        .APP_ADDR_WIDTH(APP_ADDR_WIDTH),
        .CHANNEL_NUM(CHANNEL_NUM))
    rdreq_sel_0
    (
        .clk        ( clk           ),
        .rst_n      ( rst_n         ),
        //to user
        .rd_req_    ( rd_req_       ),
        .rd_addr_   ( rd_addr_      ),
        .rd_num_    ( rd_num_       ),
        .rd_data_   ( rd_data_      ),
        .rd_grant_  ( rd_grant_     ),
        .rd_finish_ ( rd_finish_    ),
        // to dram
        .rd_req     ( rd_req        ),
        .rd_addr    ( rd_addr       ),
        .rd_num     ( rd_num        ),
        .rd_data    ( rd_data       ),
        .rd_grant   ( rd_grant      ),
        .rd_finish  ( rd_finish     )
    );


    wrreq_sel 
    #(  .APP_DATA_WIDTH(APP_DATA_WIDTH),
        .APP_ADDR_WIDTH(APP_ADDR_WIDTH),
        .CHANNEL_NUM(CHANNEL_NUM))
    wrreq_sel_0
    (
        .clk        ( clk           ),
        .rst_n      ( rst_n         ),
        //to user
        .wr_req_    ( wr_req_       ),
        .wr_addr_   ( wr_addr_      ),
        .wr_num_    ( wr_num_       ),
        .wr_data_   ( wr_data_      ),
        .wr_mask_   ( wr_mask_      ),
        .wr_grant_  ( wr_grant_     ),
        .wr_finish_ ( wr_finish_    ),
        // to dram
        .wr_req     ( wr_req        ),
        .wr_addr    ( wr_addr       ),
        .wr_num     ( wr_num        ),
        .wr_data    ( wr_data       ),
        .wr_mask    ( wr_mask       ),
        .wr_grant   ( wr_grant      ),
        .wr_finish  ( wr_finish     )

    );    
end else begin

    assign rd_req  = rd_req_;
    assign rd_addr = rd_addr_;
    assign rd_num  = rd_num_;

    assign rd_data_  = rd_data;
    assign rd_grant_ = rd_grant;
    assign rd_finish_= rd_finish;


    assign wr_req  = wr_req_;
    assign wr_addr = wr_addr_;
    assign wr_num  = wr_num_;
    assign wr_data = wr_data_;
    assign wr_mask = wr_mask_;

    assign rd_grant_ = rd_grant;
    assign rd_finish_= rd_finish;



end
endgenerate

endmodule
