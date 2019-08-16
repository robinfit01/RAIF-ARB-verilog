/************************************************************************************
*   Name         :RAIF.vh 
*   Description  :request and acknowledge interface,verilog head,
*                 contains other STD logic
*   Origin       :190716
*                 190723
*   Author       :helrori
*   Reference    :UN/PACK_ARRAY
************************************************************************************/
/*

    下图描述了 raif_arb.v(CHANNEL_NUM==3)的RTL结构
    |                                                                              |
    |                               USER LOGIC(RAIF)                               |
    +------------------------------------------------------------------------------+
           +  +                          +  +                            +  +
           |  |2                         |  |1                           |  |0(High Priority)
    +------------------------------------------------------------------------------+
    |  READ|  |WRITE                 READ|  |WRITE                   READ|  |WRITE |
    |      |  |RAXX_RCIF                 |  |RAXX_RCIF          RAXX_RCIF|  |      |
    |      |  |                          |  |                            |  |      |
    |      |  |                      +-----------------------------------+  |      |
    |      |  |                      |   |  |                               |      |
    |      |  |         +----------------+  +-----------------+             |      |
    |      |  |         |            |                        |             |      |
    |      |  +---------------------------------+             |             |      |
    |      |            |            |          |             |             |      |
    |      |2           |1           |0         |2            |1            |0     |
    |  +---+------------+------------+---+  +---+-------------+-------------+---+  |
    |  |            RARD_RCIF            |  |             RAWR_RCIF             |  |
    |  |                                 |  |                                   |  |
    |  |           rdreq_sel.v           |  |            wrreq_sel.v            |  |
    |  |         CHANNEL_NUM==3          |  |          CHANNEL_NUM==3           |  |
    |  |                                 |  |                                   |  |
    |  |            RARD_TRIF            |  |             RAWR_TRIF             |  |
    |  +----------------+----------------+  +-----------------+-----------------+  |
    |                   +----------------+  +-----------------+                    |
    |                                    |  |RAXX_TRIF                  raif_arb.v |
    +------------------------------------------------------------------------------+
                                         |  |                    
    +------------------------------------+--+--------------------------------------+
    |                         DRAM IP(RAIF,CHANNEL_NUM==1)                         |
    |                                                                              |
*/
/*

    下图描述了 RAIF(RAIFWRDATA_PREFETCH="TRUE") 接口标准时序，不同箭头仅用于区分与另一方向不同
    ->                      wr_request,//|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [APP_ADDR_WIDTH-1:0]wr_addr,   //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [9    :0]           wr_num,    //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//pls  512 >= xx_num  > 0,wr_num==1 suggest write 1x8xDQW bits
    ->  [APP_DATA_WIDTH-1:0]wr_data,   //XXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXXXXXX//pre-fetch
    ->[APP_DATA_WIDTH/8-1:0]wr_mask,   //XXXX|   |   |   |   |   |   |   |   |   |XXXXXXXX//pre-fetch
    <-                      wr_grant,  //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|________//
    <-                      wr_finish, //___________________________________________|~~|__//
    <-                      wr_busy,   //|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|__//(非必要)
    ->                      rd_request,//|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [APP_ADDR_WIDTH-1:0]rd_addr,   //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [9    :0]           rd_num,    //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//pls  512 >= xx_num  > 0,wr_num==1 suggest read 1x8xDQW bits
    <-  [APP_DATA_WIDTH-1:0]rd_data,   //XXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXXXXXX//
    <-                      rd_grant,  //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|________//
    <-                      rd_finish, //___________________________________________|~~|__//
    <-                      rd_busy,   //|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|__//(非必要)
    
    下图描述了 RAIF(RAIFWRDATA_PREFETCH="FALSE") 接口标准时序
    ->                      wr_request,//|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [APP_ADDR_WIDTH-1:0]wr_addr,   //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [9    :0]           wr_num,    //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//pls  512 >= xx_num  > 0 ,wr_num==1 suggest write 1x8xDQW bits
    ->  [APP_DATA_WIDTH-1:0]wr_data,   //XXXXXXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXX//no pre-fetch
    ->[APP_DATA_WIDTH/8-1:0]wr_mask,   //XXXXXXXX|   |   |   |   |   |   |   |   |   |XXXX//no pre-fetch
    <-                      wr_grant,  //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|________//
    <-                      wr_finish, //___________________________________________|~~|__//
    <-                      wr_busy,   //|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|__//(非必要)
    ->                      rd_request,//|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [APP_ADDR_WIDTH-1:0]rd_addr,   //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//
    ->  [9    :0]           rd_num,    //|~~~~~~~~~~~~~~~~keep to finish~~~~~~~~~~~~~~~|__//pls  512 >= xx_num  > 0 ,wr_num==1 suggest read 1x8xDQW bits
    <-  [APP_DATA_WIDTH-1:0]rd_data,   //XXXX| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |XXXXXXXX//
    <-                      rd_grant,  //____|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|________//
    <-                      rd_finish, //___________________________________________|~~|__//
    <-                      rd_busy,   //|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|__//(非必要)
    两种接口时序只有数据是否需要预取的区别,RAIF接口不关心： RAIFWRDATA_PREFETCH等于多少 ，两种都可以.
    如果用户仅使用 raif_arb.v模块 ，用户必须了解 DRAM IP 的 RAIF接口类型，以此确定 USER LOGIC的 
    WR FIFO是否需要 SHOW-AHEAD/PRE-FETCH . RAIF接口包含读写两条线路，当 DRAM IP不支持同时读写时，
    且 RAIF接口的读写请求同时到达时， 会优先执行读/写，DRAM IP内的读写优先级有关.
    除此之外，建议：128 >= xx_num  > 0;极限读写数量可以到达 1024 > xx_num  > 0.
    xx_num 指出 xx_data 的读写个数. xx_addr 一般是 DRAM 的实际地址，所以对于DDR3 需要8对齐,即读一个xx_data
    地址就要加8
 
*/
`ifndef _RAIF_VH_ 
`define _RAIF_VH_

//  接收组
`define RARD_RCIF   input  wire              [CHANNEL_NUM  -1:0]rd_req_      ,\
                    input  wire [APP_ADDR_WIDTH*CHANNEL_NUM-1:0]rd_addr_     ,\
                    input  wire             [10*CHANNEL_NUM-1:0]rd_num_      ,\
                    output wire [APP_DATA_WIDTH*CHANNEL_NUM-1:0]rd_data_     ,\
                    output wire              [CHANNEL_NUM  -1:0]rd_grant_    ,\
                    output wire              [CHANNEL_NUM  -1:0]rd_finish_   

`define RAWR_RCIF   input  wire              [CHANNEL_NUM  -1:0]wr_req_      ,\
                    input  wire [APP_ADDR_WIDTH*CHANNEL_NUM-1:0]wr_addr_     ,\
                    input  wire             [10*CHANNEL_NUM-1:0]wr_num_      ,\
                    input  wire [APP_DATA_WIDTH*CHANNEL_NUM-1:0]wr_data_     ,\
                    input  wire [APP_DATA_WIDTH*CHANNEL_NUM/8-1:0]wr_mask_   ,\
                    output wire              [CHANNEL_NUM  -1:0]wr_grant_    ,\
                    output wire              [CHANNEL_NUM  -1:0]wr_finish_   
`define RAXX_RCIF   `RARD_RCIF,`RAWR_RCIF
                    
//  发射组 (单通道)
`define RARD_TRIF   output reg                       rd_req      ,\
                    output reg   [APP_ADDR_WIDTH-1:0]rd_addr     ,\
                    output reg   [9    :0]           rd_num      ,\
                    input  wire  [APP_DATA_WIDTH-1:0]rd_data     ,\
                    input  wire                      rd_grant    ,\
                    input  wire                      rd_finish

`define RAWR_TRIF   output reg                       wr_req      ,\
                    output reg   [APP_ADDR_WIDTH-1:0]wr_addr     ,\
                    output reg   [9    :0]           wr_num      ,\
                    output reg   [APP_DATA_WIDTH-1:0]wr_data     ,\
                    output reg [APP_DATA_WIDTH/8-1:0]wr_mask     ,\
                    input  wire                      wr_grant    ,\
                    input  wire                      wr_finish
`define RAXX_TRIF   `RARD_TRIF,`RAWR_TRIF

/************************************************************************************
*       verilog 端口不能定义为二维数组，用以下宏代替。
*       例子：
*       module example (
*       input  [63:0] pack_4_16_in,
*       output [31:0] pack_16_2_out
*       );
*       `define NEW_ARRAY_PACK_UNPACK
*        wire [3:0] in [0:15];
*       `UNPACK_ARRAY(4,16,in,pack_4_16_in)
*       wire [15:0] out [0:1];
*       `PACK_ARRAY(16,2,in,pack_16_2_out)
*       endmodule // example
************************************************************************************/

// define NEW_ARRAY_PACK_UNPACK frist
`define NEW_ARRAY_PACK_UNPACK genvar pk_idx; genvar unpk_idx;
// pack 2D-array to 1D-array
`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST,name) \
                generate \
                for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) \
                begin:name \
                        assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; \
                end \
                endgenerate
// unpack 1D-array to 2D-array
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC,name) \
                generate \
                for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) \
                begin:name \
                        assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; \
                end \
                endgenerate


/*************************************************************************************
*       计算1的个数
*************************************************************************************/
module ctos 
#(
    parameter N = 8 //N>=1
)
(
        input   [N-1:0] in,
        output  reg [$clog2(N+1)-1:0]ct
);
integer idx;
always @* begin
  ct = 'b0;
  for( idx = 0; idx<N; idx = idx + 1) begin
    ct = ct + in[idx];
  end
end
endmodule
/************************************************************************************
*       标准编码器 行为描述
*       such as   in=8'b0000_0100
*                out=3'd2
************************************************************************************/
module enc 
#(
    parameter N = 8 //N>=2
)
(
    input wire [N-1:0] in,
    output reg [$clog2(N)-1:0] out
);
integer i;
always @* begin
    out = 'b0; // default value if 'in' is all 0's
    for (i=0; i<N; i=i+1)
        if (in[i]) out = i;
end
endmodule
/************************************************************************************
*       计算前导零个数,以独热码表示(可表示[0:N]个，可接受全0/1的情况，这时out[N]=1),门级描述
*       Leading Zero Count,one-hot output
*       such as    in=8'b0001_0100 高位有3个连0
*                out=9'b00000_1000 out[3]=1
************************************************************************************/
module clzx #(
    parameter N = 8 //N >=1
) (
    input wire  [N-1:0] in,
    output wire [N  :0] out
);
wire [N-1:0]bfw;
generate 
    genvar j;
    for (j=0;j<N+1;j=j+1) begin:CLZ
        if (j==0) begin:ST0
            assign bfw[0] = 0 | in[N-1];
            assign out[0] = bfw[0];
        end else if(j==N)begin:STN
            assign out[j] =~bfw[j-1];
        end else begin:STX
            assign bfw[j] =  bfw[j-1]  | in[N-j-1];
            assign out[j] =(~bfw[j-1]) & bfw[j];
        end
    end
endgenerate
endmodule
/************************************************************************************
*       标准仲裁器，Finds first '1' bit in 'in' 。门级描述。
*       该逻辑与 clzx 类似，但是是输出第一个1的位置(独热码)所以不接受全0的情况,而且注意
*       是从最低位开始找1!例如：in=8'b0001_0100 低位有2个连0
*                            out=8'b0000_0100 out[2]=1
************************************************************************************/
module arb
#(
    parameter N=8 //N>=2
)
(
    input  [N-1:0] in ,
    output [N-1:0] out 
);
wire   [N-1:0] c ;
assign c = {(~in[N-2:0] & c[N-2:0]),1'b1} ;
assign out = in & c ;
endmodule
/************************************************************************************
*       优先编码器
*
************************************************************************************/
module pri_enc
#(
    parameter N=8 //N>=2
)
(
    input  [N-1:0] in ,
    output [$clog2(N)-1:0] out 
);
wire [N-1:0]bfw;
arb #(N)arb_0(.in(in),.out(bfw));
enc #(N)enc_0(.in(bfw),.out(out));
endmodule


/************************************************************************************
*       按键消抖
*
************************************************************************************/
module keyhold
#(
    parameter CLOCKPERIOD=40 
)
(
    input      clk,
    input      rst_n,

    input      key ,
    output     keyhold,
    output reg sw
);
localparam CT=1000000/CLOCKPERIOD;
reg  [$clog2(CT):0]cnt;
reg  [9:0]shift;
assign keyhold=&shift;
reg  [1:0]bf0;
wire keyholdpp=(~bf0[1])&(bf0[0]);
always@(posedge clk or negedge rst_n)begin
	if ( !rst_n ) begin
		cnt<='d0;
		shift<='d0;
		bf0<='d0;
		sw<='d0;
	end else begin
		if (cnt==CT) begin
			cnt<='d0;
			shift<={shift,key};
		end else begin
			cnt<=cnt+1'd1;
		end
		bf0<={bf0,keyhold};
		if(keyholdpp)
			sw<=~sw;
	end
end
endmodule

`endif