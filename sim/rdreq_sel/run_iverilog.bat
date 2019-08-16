iverilog.exe -D _NOMIG_DEBUG_ -o ./tb_rdreq_sel.vvp -y../../rtl/ -y../../rtl/common -y../../../mig_ddr3_ip_wrapper/ -I../../rtl/ ../../rtl/tb_rdreq_sel.v
pause
vvp tb_rdreq_sel.vvp
pause
gtkwave wave2ch.gtkw