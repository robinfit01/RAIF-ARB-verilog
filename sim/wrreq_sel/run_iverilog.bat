iverilog.exe -D _NOMIG_DEBUG_ -o ./tb_wrreq_sel.vvp -y../../rtl/ -y../../rtl/common -y../../../mig_ddr3_ip_wrapper/ -I../../rtl/ ../../rtl/tb_wrreq_sel.v
pause
vvp tb_wrreq_sel.vvp
pause
gtkwave wave.gtkw