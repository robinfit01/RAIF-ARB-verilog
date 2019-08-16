`timescale  1ns / 1ps

module tb_simple_fifo;

// simple_fifo Parameters
parameter PERIOD  = 10;
parameter width   = 8;
parameter widthu  = 3;

// simple_fifo Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;
reg   sclr                                 = 0 ;
reg   rdreq                                = 0 ;
reg   wrreq                                = 0 ;
reg   [width-1:0]  data                    = 8'hAA ;

// simple_fifo Outputs
wire  empty                                ;
wire  full                                 ;
wire  [width-1:0]  q                       ;
wire  [widthu-1:0]  usedw                  ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0,tb_simple_fifo);

    #(PERIOD*2) rst_n  =  1;
    #(PERIOD*4)
    wrreq=1;
    #(PERIOD*1)
    wrreq=0;
    #(PERIOD*8)
    rdreq=1;
    #(PERIOD*4)
    rdreq=0;
    #(PERIOD*50)
    $finish;
end

simple_fifo #(
    .width  ( width  ),
    .widthu ( widthu ))
 u_simple_fifo (
    .clk                     ( clk                 ),
    .rst_n                   ( rst_n               ),
    .sclr                    ( sclr                ),
    .rdreq                   ( rdreq               ),
    .wrreq                   ( wrreq               ),
    .data                    ( data   [width-1:0]  ),

    .empty                   ( empty               ),
    .full                    ( full                ),
    .q                       ( q      [width-1:0]  ),
    .usedw                   ( usedw  [widthu-1:0] )
);



endmodule