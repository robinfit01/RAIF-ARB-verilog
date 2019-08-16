iverilog.exe -D _DEBUG_ -o ./tb2_raif_arb.vvp -y../../../../WORK_SPACE/Verilog_HDL_CODE/sdram_v2/rtl/ -y../../rtl/ -y../../rtl/common -I../../rtl/ ../../rtl/tb2_raif_arb.v 
pause
vvp tb2_raif_arb.vvp
pause
gtkwave wave2.gtkw