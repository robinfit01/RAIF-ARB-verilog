`timescale  1ns / 1ps

module tb_wrreq_sel;

// wrreq_sel Parameters
parameter PERIOD          = 10 ;
parameter APP_DATA_WIDTH  = 128;
parameter APP_ADDR_WIDTH  = 28 ;
parameter CHANNEL_NUM     = 3  ;


wire  clk                                   ;
reg   rst_n                                = 0 ;

reg   [CHANNEL_NUM  -1:0]  wr_req_         = 0 ;
reg   [APP_ADDR_WIDTH*CHANNEL_NUM-1:0]  wr_addr_ = {28'h01,28'h02,28'h03} ;
reg   [10*CHANNEL_NUM-1:0]              wr_num_  = {10'd96,10'd86,10'd86} ;
wire  [APP_DATA_WIDTH*CHANNEL_NUM-1:0]  wr_data_ =0;
wire  [CHANNEL_NUM  -1:0]  wr_grant_       ;
wire  [CHANNEL_NUM  -1:0]  wr_finish_      ;

wire  [APP_DATA_WIDTH-1:0]  wr_data       ;
wire  wr_grant                            ;
wire  wr_finish                           ;
wire  wr_req                               ;
wire  [APP_ADDR_WIDTH-1:0]  wr_addr        ;
wire  [9    :0]  wr_num                    ;




initial
begin
    #(PERIOD*2) rst_n  =  1;
end

wrreq_sel #(
    .APP_DATA_WIDTH ( APP_DATA_WIDTH ),
    .APP_ADDR_WIDTH ( APP_ADDR_WIDTH ),
    .CHANNEL_NUM    ( CHANNEL_NUM    ))
 u_wrreq_sel (
    .clk                     ( clk                                          ),
    .rst_n                   ( ~rst                                        ),

    .wr_req_                 ( wr_req_     [CHANNEL_NUM  -1:0]              ),
    .wr_addr_                ( wr_addr_    [APP_ADDR_WIDTH*CHANNEL_NUM-1:0] ),
    .wr_num_                 ( wr_num_     [10*CHANNEL_NUM-1:0]             ),
    .wr_data_                ( wr_data_    [APP_DATA_WIDTH*CHANNEL_NUM-1:0] ),
    .wr_grant_               ( wr_grant_   [CHANNEL_NUM  -1:0]              ),
    .wr_finish_              ( wr_finish_  [CHANNEL_NUM  -1:0]              ),

    .wr_req                  ( wr_req                                       ),
    .wr_num                  ( wr_num      [9    :0]                        ),
    .wr_addr                 ( wr_addr     [APP_ADDR_WIDTH-1:0]             ),
    .wr_data                 ( wr_data     [APP_DATA_WIDTH-1:0]             ),
    .wr_grant                ( wr_grant                                     ),
    .wr_finish               ( wr_finish                                    )
);
wire dram_initdone;
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
    .wr_request              ( wr_req            ),
    .wr_data                 ( wr_data               ),//PRE-FETCH!!
    .wr_allow                ( wr_grant              ),
    .wr_busy                 (                 ),
    .wr_finish               ( wr_finish               ),

    .rd_addr                 (                 ),
    .rd_num                  (                  ),
    .rd_request              (              ),
    .rd_data                 (                 ),
    .rd_allow                (                ),
    .rd_busy                 (                 ),
    .rd_finish               (               ),
    .init_calib_complete     ( dram_initdone          ),

    .ddr3_addr               ( ddr3_addr              ),
    .ddr3_ba                 ( ddr3_ba                ),
    .ddr3_ras_n              ( ddr3_ras_n             ),
    .ddr3_cas_n              ( ddr3_cas_n             ),
    .ddr3_we_n               ( ddr3_we_n              ),
    .ddr3_reset_n            ( ddr3_reset_n           ),
    .ddr3_ck_p               ( ddr3_ck_p              ),
    .ddr3_ck_n               ( ddr3_ck_n              ),
    .ddr3_cke                ( ddr3_cke               ),
    .ddr3_cs_n               ( ddr3_cs_n              ),
    .ddr3_dm                 ( ddr3_dm                ),
    .ddr3_odt                ( ddr3_odt               ),
    .ddr3_dq                 ( ddr3_dq                ),
    .ddr3_dqs_n              ( ddr3_dqs_n             ),
    .ddr3_dqs_p              ( ddr3_dqs_p             )
);
reg on=1;
generate
genvar i;
    for (i = 0;i< CHANNEL_NUM;i=i+1 ) begin:REQ
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
                if (($random%100)>98 && on) begin
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



initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0,tb_wrreq_sel);
    wait(dram_initdone)begin


    #(PERIOD*10000)
    #(PERIOD*10000)
    wait((|wr_req_)==0)begin
        on=0;
        #(PERIOD*10)
        $display("\n[tb_wrreq_sel.v]:: Grant::%d Req::%d",REQ[0].cnt,REQ[0].cnt2);
        $display("[tb_wrreq_sel.v]:: Grant::%d Req::%d",REQ[1].cnt,REQ[1].cnt2);
        $display("[tb_wrreq_sel.v]:: Grant::%d Req::%d",REQ[2].cnt,REQ[2].cnt2);
        $finish;        
    end


        
    end


 
end

endmodule
