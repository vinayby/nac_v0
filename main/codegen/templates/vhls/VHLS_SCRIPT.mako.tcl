<%
  src_filelist_abspaths, top_function_list, vhls_build_dir = vhls_script_renderparameters
  import os
  #src_filelist_paths = src_filelist_abspaths
  src_filelist_paths = [os.path.relpath(x, os.path.abspath(_am.out_simdir)) for x in src_filelist_abspaths]
  combined_cpp = src_filelist_paths[0]
%>
open_project ${vhls_build_dir}

# default disabled
set run_export_ip 1 

if { 1 } {
set fpga_partname "xc7vx690tffg1761-2"
} else {
set fpga_partname "xc7z020clg400-1"
}


%for f in src_filelist_paths:
add_files ${f}
%endfor

if {$argc == 2} { # -f path/to/script.tcl 
%for top_function in top_function_list:
set EN_${top_function}  1
%endfor 
} else {          # -f path/to/script.tcl -tclargs EN_abc
%for top_function in top_function_list:
  set EN_${top_function}  0
  set [lindex $argv 2] 1
%endfor 
}

%for top_function in top_function_list:
if {$EN_${top_function}} {
  open_solution "s_${top_function}"
  add_files ${combined_cpp} -cflags "-DINCLUDE_${top_function}"
  set_part $fpga_partname
  create_clock -period 10 -name default
  config_rtl -encoding onehot -reset control -reset_level low
  set_top ${top_function}
  csynth_design
  if { $run_export_ip == 1 } {
    export_design -format ip_catalog
}
close_solution
}
%endfor
exit

## vim: ft=mako
