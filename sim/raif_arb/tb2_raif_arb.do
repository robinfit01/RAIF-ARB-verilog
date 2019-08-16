vlib work
vlog +define+_DEBUG_  ../../../../WORK_SPACE/Verilog_HDL_CODE/sdram_v2/rtl/mt48lc16m16a2.v ../../../../WORK_SPACE/Verilog_HDL_CODE/sdram_v2/rtl/sdram_interface.v ../../rtl/raif_arb.v ../../rtl/rdreq_sel.v ../../rtl/wrreq_sel.v ../../rtl/tb2_raif_arb.v ../../rtl/RAIF.vh ../../rtl/common/simple_fifo.v 
vsim tb2_raif_arb
#add wave /tb2_raif_arb/*
#radix hex
do wave2.do
run -all