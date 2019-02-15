<%
  import os
  import pdb
  project_name,outdir_abspath,target_dir_path,final_fileset_dir_path,vhls_build_dir,hls_modnames = sim_behav_vivado_renderparameters
  _globalargs = _am.args
  def get_relpath_to_makefile(inpath):
    return os.path.relpath(inpath, _am.out_simdir)
  four_steps_back = "../../../../"
%>

set target_dir_path "${get_relpath_to_makefile(target_dir_path)}"
set final_fileset_dir_path "${get_relpath_to_makefile(final_fileset_dir_path)}"
##set vhls_build_dir "${get_relpath_to_makefile(vhls_build_dir)}"
set vhls_build_dir "${vhls_build_dir}"

##<%def name="main_v_defs()">
##  %if _globalargs.scemi:
##+define+TOP=mkBridge  +define+BSV_SCEMI_LINK=\""$target_dir_path/vlog_dut/scemilink.vlog_fragment"\"  \
##\
##  %endif
##</%def>\

<%def name="vcs_elab_opts()">
  %if _globalargs.scemi:
+vpi -P ${four_steps_back}/directc_mkBridge.tab -full64 -load ${four_steps_back}/directc_mkBridge.so:vpi_register_tasks ${four_steps_back}/directc_mkBridge.so \
  %endif
</%def>\
#
# Generates the vivado project, add files and HLS IPs, generates simulation scripts
#
if {1} {
create_project ${project_name} $target_dir_path/${project_name} -part xc7vx690tffg1761-2 -force
} else {
create_project ${project_name} $target_dir_path/${project_name} -part xc7z020clg484-1 -force
}

config_webtalk -user off

if {1} {
set_property board_part xilinx.com:vc709:part0:1.8 [current_project]
} else {
set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
}

add_files -fileset sim_1 [glob $final_fileset_dir_path/*]
%if _globalargs.scemi:
set_property top main [get_filesets sim_1]
%else:
set_property top tb [get_filesets sim_1]
%endif
set_property top_lib xil_defaultlib [get_filesets sim_1]

# XDC constraints file
set xdcfs [glob -nocomplain $final_fileset_dir_path//*.xdc]
if {$xdcfs != "" } {
add_files -fileset constrs_1 -norecurse $xdcfs
}

# Add files for synthesis 
add_files -norecurse [glob $final_fileset_dir_path/*.hex]
add_files -norecurse [glob $final_fileset_dir_path/*.v]

set_property ip_repo_paths $vhls_build_dir [current_fileset]
update_ip_catalog
%if hls_modnames:
%for hlstopname, hlsinstancename in hls_modnames:
create_ip -name ${hlstopname} -vendor xilinx.com -library hls -version 1.0 -module_name ${hlsinstancename}
generate_target all [get_files $target_dir_path/${project_name}/${project_name}.srcs/sources_1/ip/${hlsinstancename}/${hlsinstancename}.xci]
#generate_target {instantiation_template} [get_files $target_dir_path/${project_name}/${project_name}.srcs/sources_1/ip/${hlsinstancename}/${hlsinstancename}.xci]
#generate_target {simulation} [get_files  $target_dir_path/${project_name}/${project_name}.srcs/sources_1/ip/${hlsinstancename}/${hlsinstancename}.xci]
%endfor 
%endif

%if _globalargs.simulator == 'xsim': 
set_property target_simulator "XSim" [current_project] 
set_property xsim.simulate.runtime {500000ns} [get_filesets sim_1]
#launch_simulation -absolute_path -scripts_only
export_simulation -force -simulator xsim -directory "."
exit
%elif _globalargs.simulator in ['vcs', 'myvcs']:

  set CXX_ "g++"
  set CC_ "gcc"
  if {  {exec gcc -dumpversion} >= 5 } { 
  if { [file exists "/usr/bin/g++-4.9"] } {
  set CXX_ "/usr/bin/g++-4.9"
  set CC_ "/usr/bin/gcc-4.9"
  } else {
  set CXX_ "/usr/bin/g++-4.8"
  set CC_ "/usr/bin/gcc-4.8"

  }
  }

set_property target_simulator VCS [current_project]
set_property vcs.simulate.runtime {500000000ns} [get_filesets sim_1]
set_property -name {vcs.simulate.vcs.more_option} -value {-ucli} -objects [get_filesets sim_1]   
set_property compxlib.vcs_compiled_library_dir ${_globalargs.simulator_simlib_path} [current_project]
##set_property -name {vcs.compile.vlogan.more_options} -value {-override_timescale=1ns/1ns \${main_v_defs()}} -objects [get_filesets sim_1] 
set_property -name {vcs.compile.vlogan.more_options} -value {-override_timescale=1ns/1ps -sverilog } -objects [get_filesets sim_1] 
set_property -name {vcs.elaborate.vcs.more_options} -value " -cc $CC_ -cpp $CXX_ \${vcs_elab_opts()} " -objects [get_filesets sim_1] 
launch_simulation -scripts_only
export_simulation -lib_map_path "${_globalargs.simulator_simlib_path}" -force -simulator vcs -directory "."
#get_property -name {vcs.elaborate.vcs.more_options} -object [get_filesets sim_1] 
exit
%else:
  ONLY_XSIM_OR_VCS_SO_FAR
%endif
#
# Next steps: 
# 

## vim: ft=mako
