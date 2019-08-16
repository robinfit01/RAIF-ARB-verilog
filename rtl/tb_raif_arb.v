/************************************************************************************
*   Name         :tb_raif_arb
*   Description  :tb2 for XILINX MIG sim only
*   Origin       :190722
*   Author       :helrori2011@gmail.com
*   Reference    :
************************************************************************************/

`timescale  1ns / 1ps

module tb_raif_arb;
integer seed=3;

// raif_arb Parameters
parameter PERIOD          = 10 ;
parameter APP_DATA_WIDTH  = 128;
parameter APP_ADDR_WIDTH  = 28 ;
parameter CHANNEL_NUM     = 2  ;

// raif_arb Inputs
wire  clk                                   ;
reg   rst_n                                = 0 ;

reg               [CHANNEL_NUM  -1:0]rd_req_  ='b0    ;
reg  [APP_ADDR_WIDTH*CHANNEL_NUM-1:0]rd_addr_ ={28'd128,28'd0}     ;
reg              [10*CHANNEL_NUM-1:0]rd_num_  ={10'd128,10'd128}    ;
wire [APP_DATA_WIDTH*CHANNEL_NUM-1:0]rd_data_     ;
wire              [CHANNEL_NUM  -1:0]rd_grant_    ;
wire              [CHANNEL_NUM  -1:0]rd_finish_   ;

reg               [CHANNEL_NUM  -1:0]wr_req_  ='b0    ;
reg  [APP_ADDR_WIDTH*CHANNEL_NUM-1:0]wr_addr_ ={28'd128,28'd0}    ;
reg              [10*CHANNEL_NUM-1:0]wr_num_  ={10'd128,10'd128}  ;
reg  [APP_DATA_WIDTH*CHANNEL_NUM-1:0]wr_data_ ='b0     ;
wire              [CHANNEL_NUM  -1:0]wr_grant_    ;
wire              [CHANNEL_NUM  -1:0]wr_finish_   ;

wire                      rd_req      ;
wire  [APP_ADDR_WIDTH-1:0]rd_addr     ;
wire  [9    :0]           rd_num      ;
wire  [APP_DATA_WIDTH-1:0]rd_data     ;
wire                      rd_grant    ;
wire                      rd_finish   ;
wire                      wr_req      ;
wire  [APP_ADDR_WIDTH-1:0]wr_addr     ;
wire  [9    :0]           wr_num      ;
wire  [APP_DATA_WIDTH-1:0]wr_data     ;
wire                      wr_grant    ;
wire                      wr_finish   ;

// raif_arb Outputs





initial
begin
    #(PERIOD*2) rst_n  =  1;
end

raif_arb #(
    .APP_DATA_WIDTH ( APP_DATA_WIDTH ),
    .APP_ADDR_WIDTH ( APP_ADDR_WIDTH ),
    .CHANNEL_NUM    ( CHANNEL_NUM    ))
 u_raif_arb (
    .clk                     ( clk          ),
    .rst_n                   ( ~rst        ),

    .rd_req_                 ( rd_req_),
    .rd_addr_                ( rd_addr_),
    .rd_num_                 ( rd_num_),
    .rd_data_                ( rd_data_),
    .rd_grant_               ( rd_grant_),
    .rd_finish_              ( rd_finish_),
    .wr_req_                 ( wr_req_),
    .wr_addr_                ( wr_addr_),
    .wr_num_                 ( wr_num_),
    .wr_data_                ( wr_data_),
    .wr_grant_               ( wr_grant_),
    .wr_finish_              ( wr_finish_),

    .rd_req                  ( rd_req),
    .rd_addr                 ( rd_addr),
    .rd_num                  ( rd_num),
    .rd_data                 ( rd_data),
    .rd_grant                ( rd_grant),
    .rd_finish               ( rd_finish),
    .wr_req                  ( wr_req),
    .wr_addr                 ( wr_addr ),
    .wr_num                  ( wr_num),
    .wr_data                 ( wr_data),
    .wr_grant                ( wr_grant),
    .wr_finish               ( wr_finish)
);
ddr3_core_alignv #(
    .APP_DATA_WIDTH ( APP_DATA_WIDTH  ),
    .APP_ADDR_WIDTH ( APP_ADDR_WIDTH  )
)
 u_ddr3_core_alignv (
    .clk_200Mhz              (  ),
    .rst_n                   ( rst_n                  ),//   -->MIG
    .clk                     ( clk                    ),//MIG-->user
    .rst                     ( rst                    ),//MIG-->user

    //connect to the arbitrator_mini
    .wr_addr                 ( wr_addr               ),
    .wr_num                  ( wr_num                ),
    .wr_request              ( wr_req                ),
    .wr_data                 ( wr_data               ),//PRE-FETCH!!
    .wr_allow                ( wr_grant              ),
    .wr_busy                 (                       ),
    .wr_finish               ( wr_finish             ),

    .rd_addr                 ( rd_addr                ),
    .rd_num                  ( rd_num                 ),
    .rd_request              ( rd_req                 ),
    .rd_data                 ( rd_data                ),
    .rd_allow                ( rd_grant               ),
    .rd_busy                 (                        ),
    .rd_finish               ( rd_finish              ),
    .init_calib_complete     ( dram_initdone          )
);

reg onw=1;
generate
genvar i;
    for (i = 0;i< CHANNEL_NUM;i=i+1 ) begin:REQW
        reg [1:0]st='b0;
        wire r;
        reg s=1;
        reg [31:0]cnt=0,cnt2=0;

        always @(posedge clk ) begin
            case(st)
            0:begin
                if(dram_initdone )
                    st<=st+1;
            end
            1:begin
                if (($random(seed)%100)>98 && onw) begin
                    // $display("wr seed:%t",seed);
                    cnt2<=cnt2+1;
                    st<=st+1;
                    wr_req_[i]<=1;
                end 
            end
            2:begin
                if(wr_finish_[i])begin
                    wr_req_[i]<=0;
                    st<='b1;
                    s<=1;
                end 
                if(wr_grant_[i] && s)begin
                    // $display("1");
                    cnt<=cnt+1;
                    s<=0;
                end
                    
            end
            default:;
            endcase
        end        
    end
endgenerate

reg onr=1;
generate
    for (i = 0;i< CHANNEL_NUM;i=i+1 ) begin:REQR
        reg [1:0]st='b0;
        wire r;
        reg s=1;
        reg [31:0]cnt=0,cnt2=0;

        always @(posedge clk ) begin
            case(st)
            0:begin
                if(dram_initdone )
                    st<=st+1;
            end
            1:begin
                if (($random(seed)%100)>98 && onr) begin
                    cnt2<=cnt2+1;
                    st<=st+1;
                    rd_req_[i]<=1;
                end 
            end
            2:begin
                if(rd_finish_[i])begin
                    rd_req_[i]<=0;
                    st<='b1;
                    s<=1;
                end 
                if(rd_grant_[i] && s)begin
                    // $display("1");
                    cnt<=cnt+1;
                    s<=0;
                end
                    
            end
            default:;
            endcase
        end        
    end
endgenerate



initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0,tb_raif_arb);
    wait(dram_initdone)begin


    #(PERIOD*10000)
    $display("wr time:%t",$time);
    
    #(PERIOD*10000)
    wait((|wr_req_)==0)begin
        onw=0;
        wait((|rd_req_)==0)begin
            onr=0;
            #(PERIOD*10)
            $display("\n[tb_raif_arb.v WRCH0]:: Grant::%d Req::%d",REQW[0].cnt,REQW[0].cnt2);
            $display("[tb_raif_arb.v WRCH1]:: Grant::%d Req::%d",REQW[1].cnt,REQW[1].cnt2);
            $display("\n[tb_raif_arb.v RDCH0]:: Grant::%d Req::%d",REQR[0].cnt,REQR[0].cnt2);
            $display("[tb_raif_arb.v RDCH1]:: Grant::%d Req::%d",REQR[1].cnt,REQR[1].cnt2);

            $finish;              
        end
      
    end
    end

end

endmodule
