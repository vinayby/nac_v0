<%
  import os
  project_name,outdir_abspath,target_dir_path,final_fileset_dir_path,vhls_build_dir,hls_modnames = params
  reports_dir = os.path.join(outdir_abspath, "fpga")
  def get_relpath_to_makefile(inpath):
    return os.path.relpath(inpath, _am.out_simdir)
%>
#
# Generates the vivado project, add files and HLS IPs, generates simulation scripts
# -tclargs [arg1 [arg2]]
# arg1 : mkTopName (default: mkTop)
# arg2 : synth -- reruns synthesis (default)
#        synth_open --  uses existing sythesis product
#        impl  -- synth and do_impl 
#        impl_only -- synth_open and do_impl
#        impl_open -- 
         
set target_dir_path "${get_relpath_to_makefile(target_dir_path)}"
set reports_dir "${get_relpath_to_makefile(reports_dir)}"

open_project $target_dir_path/${project_name}/${project_name}.xpr

set do_rerun_synth 1
set do_open_synth 1
set do_impl_too 0
set top_module "mkTop"
if {$argc == 2 } {
  set argv1  [lindex $argv 1]
  if {$argv1 == "synth_open"} {
    set do_rerun_synth 0
    set do_open_synth 1
} elseif {$argv1 == "impl"} {
  set do_rerun_synth 1
  set do_impl_too 1
} elseif {$argv1 == "impl_only"} {
  set do_rerun_synth 0
  set do_open_synth 0
  set do_impl_too 1
} elseif {$argv1 == "impl_open"} { 
  set do_rerun_synth 0
  set do_impl_too 0
}
}
if {$argc == 1 } {
  set top_module [lindex $argv 0]
}
config_webtalk -user off
puts $top_module 
set_property top $top_module [current_fileset]

if { $do_rerun_synth == 1} {
  reset_run synth_1
  launch_runs synth_1 -jobs 4
  wait_on_run synth_1 
}

if { $do_open_synth == 1} {
open_run synth_1 -name synth_1
report_utilization -file $reports_dir/<%text>${top_module}</%text>_postsynth_utilization_report.rpt
report_utilization -hierarchical -format xml -file $reports_dir/<%text>${top_module}</%text>_postsynth_utilization_report_hier.xml
report_utilization -hierarchical -file $reports_dir/<%text>${top_module}</%text>_postsynth_utilization_report_hier.rpt
report_timing -file $reports_dir/<%text>${top_module}</%text>_postsynth_timing_report.rpt
}

if {$do_impl_too == 1} {
  # launch run impl
  #set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
  launch_runs impl_1 
  wait_on_run impl_1
  }  
 
  open_run impl_1
  report_timing -file $reports_dir/<%text>${top_module}</%text>_postpnr_timing_report.rpt
  report_utilization -file $reports_dir/<%text>${top_module}</%text>_postpnr_utilization_report.rpt
  report_utilization -hierarchical -format xml -file $reports_dir/<%text>${top_module}</%text>_postpnr_utilization_report_hier.xml
  report_utilization -hierarchical -file $reports_dir/<%text>${top_module}</%text>_postpnr_utilization_report_hier.rpt



## vim: ft=mako

