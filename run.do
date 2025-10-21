quit -sim
.main clear

vlog apb_interface.sv
vlog apb_master.sv  
vlog apb_slave.sv
vlog tb.sv

vopt +acc tb_apb -o test

vsim test

add wave -r *

run 1000ns
