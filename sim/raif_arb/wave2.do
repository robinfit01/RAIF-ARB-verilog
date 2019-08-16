onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb2_raif_arb/clk_ref
add wave -noupdate /tb2_raif_arb/clk
add wave -noupdate /tb2_raif_arb/rst_n
add wave -noupdate -expand -subitemconfig {{/tb2_raif_arb/rd_req_[1]} {-color Orange -height 18} {/tb2_raif_arb/rd_req_[0]} {-color Orange -height 18}} /tb2_raif_arb/rd_req_
add wave -noupdate -radix hexadecimal /tb2_raif_arb/rd_addr_
add wave -noupdate -radix hexadecimal /tb2_raif_arb/rd_num_
add wave -noupdate -radix hexadecimal /tb2_raif_arb/rd_data_
add wave -noupdate -expand -subitemconfig {{/tb2_raif_arb/rd_grant_[1]} {-color Orange -height 18} {/tb2_raif_arb/rd_grant_[0]} {-color Orange -height 18}} /tb2_raif_arb/rd_grant_
add wave -noupdate /tb2_raif_arb/rd_finish_
add wave -noupdate -expand -subitemconfig {{/tb2_raif_arb/wr_req_[1]} {-color Turquoise -height 18} {/tb2_raif_arb/wr_req_[0]} {-color Turquoise -height 18}} /tb2_raif_arb/wr_req_
add wave -noupdate -radix hexadecimal /tb2_raif_arb/wr_addr_
add wave -noupdate -radix hexadecimal /tb2_raif_arb/wr_num_
add wave -noupdate -radix hexadecimal /tb2_raif_arb/wr_data_
add wave -noupdate -expand -subitemconfig {{/tb2_raif_arb/wr_grant_[1]} {-color Turquoise -height 18} {/tb2_raif_arb/wr_grant_[0]} {-color Turquoise -height 18}} /tb2_raif_arb/wr_grant_
add wave -noupdate /tb2_raif_arb/wr_finish_
add wave -noupdate /tb2_raif_arb/rd_req
add wave -noupdate -radix unsigned /tb2_raif_arb/rd_addr
add wave -noupdate -radix hexadecimal /tb2_raif_arb/rd_num
add wave -noupdate -radix hexadecimal /tb2_raif_arb/rd_data
add wave -noupdate /tb2_raif_arb/rd_grant
add wave -noupdate /tb2_raif_arb/rd_finish
add wave -noupdate /tb2_raif_arb/wr_req
add wave -noupdate -radix unsigned /tb2_raif_arb/wr_addr
add wave -noupdate -radix hexadecimal /tb2_raif_arb/wr_num
add wave -noupdate -radix hexadecimal /tb2_raif_arb/wr_data
add wave -noupdate /tb2_raif_arb/wr_grant
add wave -noupdate /tb2_raif_arb/wr_finish
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4202222 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 161
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {14924495 ps}
