iverilog.exe -D _NOMIG_DEBUG_ -o ./tb_raif_arb.vvp -y../../../../WORK_SPACE/Verilog_HDL_CODE/sdram_v2/rtl/ -y../../rtl/ -y../../rtl/common -y../../../mig_ddr3_ip_wrapper/ -I../../rtl/ ../../rtl/tb_raif_arb.v 
pause
vvp tb_raif_arb.vvp
pause
gtkwave wave.gtkw