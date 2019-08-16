/************************************************************************************
*   Name         :rdreq_sel
*   Description  :读请求仲裁器。遵循原则：先来后到(FIFO)，先来先处理，同时来到时安装固有优先级
*                 先后处理。接口：RARD_XXIF，完全符合 RAIF接口时序
*   Origin       :190716
*   Author       :helrori2011@gmail.com
*   Reference    :
************************************************************************************/
`include "RAIF.vh"
module rdreq_sel
#(
    parameter APP_DATA_WIDTH = 128  ,
	parameter APP_ADDR_WIDTH = 28   ,
    parameter CHANNEL_NUM    = 2    //CHANNEL_NUM >=2
)
(
    // clock
    input       clk     ,
    input       rst_n   ,
    // connect to user IF
    `RARD_RCIF          ,
    // connect to ddr3_core.v
    `RARD_TRIF
);
/*
*   unpack 1D-array to 2D-array;pack 2D-array to 1D-array
*/
`NEW_ARRAY_PACK_UNPACK

wire [APP_ADDR_WIDTH-1:0] rd_addr_2D [0:CHANNEL_NUM-1];
`UNPACK_ARRAY(APP_ADDR_WIDTH,CHANNEL_NUM,rd_addr_2D,rd_addr_,d)

wire [10-1:0] rd_num_2D [0:CHANNEL_NUM-1];
`UNPACK_ARRAY(10,CHANNEL_NUM,rd_num_2D,rd_num_,e)

wire [APP_DATA_WIDTH-1:0] rd_data_2D [0:CHANNEL_NUM-1];
`PACK_ARRAY(APP_DATA_WIDTH,CHANNEL_NUM,rd_data_2D,rd_data_,f)

/************************************************************************************
*   rd_req_ posedge detect
*
************************************************************************************/
genvar i;
generate 
    wire    [CHANNEL_NUM-1:0]reqpp;
    reg     [1:0]bf_ch[CHANNEL_NUM-1:0];
    for (i = 0;i < CHANNEL_NUM;i = i + 1) begin:F1
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                bf_ch[i] <= 1'd0;
            end else begin
                bf_ch[i] <= {bf_ch[i],rd_req_[i]};
            end
        end
        assign reqpp[i]=(~bf_ch[i][1]&bf_ch[i][0]);
    end
endgenerate
/***********************************************************************************
* 请求缓存FIFO示意：(CHANNEL_NUM==4)
* Priority       3   2   1   0(H)
*              +-------+---+---+
*              |   |XXX|XXX|XXX+---->3个请求同时发生,根据固有优先级,先处理通道0
*              +---------------+   
*              |XXX|   |XXX|   +---->2个请求同时发生,根据固有优先级,先处理通道1
*              +---------------+ FIFO_DEEP
*              |   |XXX|   |   |
*              +---------------+
*              |XXX|   |   |   |
*              +-------+---+---+
* CHANNEL_NUM    3   2   1   0  
***********************************************************************************/
initial begin $display("\n[rdreq_sel.v]::\nCHANNEL_NUM(width)::%2d\nclog2(CHANNEL_NUM)::%2d\nFIFO DEEP\t  ::%2d\n",CHANNEL_NUM,$clog2(CHANNEL_NUM),2**$clog2(CHANNEL_NUM));end
reg                         rdfifo;
wire                        empty;
wire    [CHANNEL_NUM-1:0]   q;
wire    [$clog2(CHANNEL_NUM+1)-1:0]ct;
reg     [$clog2(CHANNEL_NUM+1)-1:0]ctbf;
reg     [CHANNEL_NUM-1:0]   qbf;
wire    [CHANNEL_NUM-1:0]   qbf_pri;
simple_fifo 
#(
    .width  ( CHANNEL_NUM ),
    .widthu ( $clog2(CHANNEL_NUM) )
)
simple_fifo_0
(
    .clk                     ( clk          ),
    .rst_n                   ( rst_n        ),
    .sclr                    ( ~rst_n       ),
    .rdreq                   ( rdfifo       ),
    .wrreq                   ( |reqpp       ),
    .data                    (  reqpp       ),

    .empty                   ( empty        ),
    .full                    (              ),
    .q                       ( q            ),//pre-fetch
    .usedw                   (              )
);
/************************************************************************************
*   main FSM
*
************************************************************************************/
ctos #(CHANNEL_NUM)ctos_0(.in(q),.ct(ct));
arb  #(CHANNEL_NUM)arb_0(.in(qbf),.out(qbf_pri));
reg [CHANNEL_NUM-1:0]sw;
reg [2:0]st;
reg [$clog2(CHANNEL_NUM+1)-1:0]mulcnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        st <= 'd0;
        qbf<= 'd0;
        sw <= 'd0;
        ctbf  <=  'd0;
        mulcnt<=  'd0;
        rdfifo<= 1'd0;
    end else begin
        case (st)
            0:begin
                if(!empty)begin
                    st      <= st + 1'd1;
                    rdfifo  <=      1'd1;
                end
            end
            1:begin
                rdfifo  <= 1'd0;
                qbf     <=    q;
                ctbf    <=   ct;
                if(ct=='d1) //同一时刻只有一个请求
                    st <= st + 1'd1;
                else        //同一时刻有多个请求
                    st <= st +  'd2;
            end
            2:begin //同一时刻只有一个请求
                sw <= qbf;//形成连接
                st <= st +  'd3;
            end
            3:begin//同一时刻有多个请求
                sw <= qbf_pri;//形成连接
                qbf<= qbf & (~qbf_pri);//清除该请求
                mulcnt <= mulcnt + 1'd1;
                st <= st +  'd1;
            end
            4:begin
                if(rd_finish)begin
                    if(mulcnt==ctbf)begin//多个请求处理完毕
                        st      <= 'd0;
                        sw      <= 'd0;
                        mulcnt  <= 'd0;
                    end else begin//处理完当次请求
                        st      <= 'd3;
                        sw      <= 'd0;
                    end
                end 
            end
            5:begin
                if(rd_finish)begin
                    st <= 'd0;
                    sw <= 'd0;//解除连接
                end
            end
            default:begin
                st <= 'd0;
                qbf<= 'd0;
                sw <= 'd0;
                ctbf  <=  'd0;
                mulcnt<=  'd0;
                rdfifo<= 1'd0;
            end
        endcase
    end
end
/***********************************************************************************
*       RARDIF 互联MUX 
*
***********************************************************************************/
// 方向指向DRAM：
localparam SELE = {{(CHANNEL_NUM-1){1'b0}},1'b1};
integer ii;
always @* begin : wide_mux
    rd_req = 1'b0;//无效态置零
    rd_addr=  'b0;
    rd_num =  'b0;
    for (ii=0; ii < CHANNEL_NUM; ii=ii+1)begin//独热码多路选择
        if ((SELE<<ii) == sw)
            rd_req = rd_req_[ii];
        if ((SELE<<ii) == sw)
            rd_addr = rd_addr_2D[ii];
        if ((SELE<<ii) == sw)
            rd_num = rd_num_2D[ii];
    end
    // if({CHANNEL_NUM{1'b0}} == sw)//无效态置零
    //     rd_req = 1'b0;
    // if({CHANNEL_NUM{1'b0}} == sw)
    //     rd_addr=  'b0;
    // if({CHANNEL_NUM{1'b0}} == sw)
    //     rd_num =  'b0;
end
// 方向指向CHANNEL：
generate
    for (i=0; i < CHANNEL_NUM; i=i+1)begin:X1 //独热码多路分配
        assign rd_data_2D[i] = (sw==(SELE<<i))?rd_data:'d0;  
        assign rd_grant_[i]  = (sw==(SELE<<i))?rd_grant:'d0;
        assign rd_finish_[i] = (sw==(SELE<<i))?rd_finish:'d0;
    end 
endgenerate
endmodule
