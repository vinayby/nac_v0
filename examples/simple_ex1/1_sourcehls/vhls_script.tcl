
open_project build_1_sourcehls

# default disabled
set run_export_ip 1 

if { 1 } {
set fpga_partname "xc7vx690tffg1761-2"
} else {
set fpga_partname "xc7z020clg400-1"
}


add_files ../../1_sourcehls/combined.cpp
add_files ../../1_sourcehls/mydefines.h
add_files ../../1_sourcehls/vhls_natypes.h

if {$argc == 2} { # -f path/to/script.tcl 
set EN_plus1  1
set EN_plus1f  1
} else {          # -f path/to/script.tcl -tclargs EN_abc
  set EN_plus1  0
  set [lindex $argv 2] 1
  set EN_plus1f  0
  set [lindex $argv 2] 1
}

if {$EN_plus1} {
  open_solution "s_plus1"
  add_files ../../1_sourcehls/combined.cpp -cflags "-DINCLUDE_plus1"
  set_part $fpga_partname
  create_clock -period 10 -name default
  config_rtl -encoding onehot -reset control -reset_level low
  set_top plus1
  csynth_design
  if { $run_export_ip == 1 } {
    export_design -format ip_catalog
}
close_solution
}
if {$EN_plus1f} {
  open_solution "s_plus1f"
  add_files ../../1_sourcehls/combined.cpp -cflags "-DINCLUDE_plus1f"
  set_part $fpga_partname
  create_clock -period 10 -name default
  config_rtl -encoding onehot -reset control -reset_level low
  set_top plus1f
  csynth_design
  if { $run_export_ip == 1 } {
    export_design -format ip_catalog
}
close_solution
}
exit

