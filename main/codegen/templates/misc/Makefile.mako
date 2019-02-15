## vim: noexpandtab ft=mako
# vim: noexpandtab ft=make
<%
import os
def get_relpath_to_pwd(inpath):
	return os.path.relpath(inpath, _am.out_simdir)
bsvpaths=_am.get_bsv_lib_paths()
bsvpaths=[os.path.abspath(x) for x in bsvpaths]
librelpaths=[get_relpath_to_pwd(x) for x in bsvpaths]
if _am.psn.is_fnoc():
	librelpaths.append('../forthnoc')
relpaths1=':'.join(librelpaths)
behavsim_tcl=os.path.join(os.path.abspath(_am.out_scriptdir), "create_project.tcl")
synthesis_tcl=  os.path.join(os.path.abspath(_am.out_scriptdir), "open_and_synthesize.tcl")
vhls_script_tcl=os.path.join(os.path.abspath(_am.out_scriptdir), "vhls_script.tcl")
behavsim_tcl=get_relpath_to_pwd(behavsim_tcl)
synthesis_tcl=get_relpath_to_pwd(synthesis_tcl)
misclibbase='../'

bsv_reserve_extra=''
if _am.has_scs_type('__ram__') or _am.has_scs_type('__mbus__'):
	bsv_reserve_extra = ':' + misclibbase + 'libs/bsv_reserve/'
	
scemi_src_list = [os.path.join('../tbscemi', x) for x in _am.args.scemi_src_list]
support_src_list = ''
if _am.args.scemi:
  support_src_list += ' ../libna/nascemi.cpp'

%>

VLOG_GEN=vlog_generated
STAGE_SIM=stage_sim
STAGE_SIM_FNOC=stage_sim_forth
vivado_hls_path:=$(subst Vivado,Vivado_HLS,$(XILINX_VIVADO))
GCCVERSIONGTEQ5 := $(shell expr `gcc -dumpversion | cut -f1 -d.` \>= 5)
CXX=g++

ifeq "$(GCCVERSIONGTEQ5)" "1"
CXX=$(shell which g++-4.9)
ifeq "$(CXX)" ""
CXX=$(shell which g++-4.8)
endif
endif

BSV_EXTRA_OPTIONS=-suppress-warnings T0054 -steps-warn-interval 200000
%if _am.args.simulator == 'iverilog':
BSV_COMPILE_EXTRA_MACRODEFS= -D IVERILOG_SIM
%elif _am.args.simulator == 'xsim':
BSV_COMPILE_EXTRA_MACRODEFS= -D VIVADO_XSIM
%endif 

.PHONY: scemi_and_link
scemi_and_link: init_ scemiv link stage_simulation_files

.PHONY: scemi_iverilog_generate
scemi_iverilog_generate: init_ scemiv link_iverilog headers tb
%if _am.psn.is_fnoc():
	cp -u -t ./	../forthnoc/*.hex
%endif 
%if _am.psn.is_connect():
	cp -t ./ <%text>${VLOG_GEN}</%text>/*.hex ## TODO stop using VLOG_GEN for this
%endif	

.PHONY: init_ 
init_: vhls_all
	mkdir -p <%text>${VLOG_GEN}</%text> <%text>${STAGE_SIM}</%text> bdir_dut info_dut sim_dir simdir_dut obj

.PHONY: compileTb_ 
compileTb_: init_
	bsc <%text>${BSV_EXTRA_OPTIONS}</%text> <%text>${BSV_COMPILE_EXTRA_MACRODEFS}</%text> -u +RTS -K32M -RTS -verilog -vdir <%text>${VLOG_GEN}</%text> -simdir sim_dir -bdir bdir_dut -info-dir info_dut -show-range-conflict -p ../src:%/Prelude:%/Libraries:%/Libraries/BlueNoC:${misclibbase}/libs/bsv/:${relpaths1}${bsv_reserve_extra} -g mkTb ../src/Tb.bsv
	@echo Compilation finished
<%doc>
# .PHONY: scemi 
scemi: init_
	bsc <%text>${BSV_EXTRA_OPTIONS}</%text> -u +RTS -K32M -RTS -sim -simdir simdir_dut -bdir bdir_dut -info-dir info_dut -show-range-conflict -p ../src:../scemi:+ -p +:<%text>${BLUESPEC_HOME}</%text>/lib/board_support/bluenoc/bridges:${misclibbase}/libs/bsv:${relpaths1}  -elab -D SCEMI_TCP -D SCEMI_CLOCK_PERIOD=1 -D MEMORY_CLOCK_PERIOD=1 -u -g mkBridge ../scemi/Bridge.bsv
	scemilink --sim --simdir=simdir_dut --path=bdir_dut:+ --port=3375 --params=scemi.params mkBridge
	bsc <%text>${BSV_EXTRA_OPTIONS}</%text> -sim -simdir simdir_dut -bdir bdir_dut -info-dir info_dut -keep-fires -D SCEMI_CLOCK_PERIOD=1.0 -D MEM_CLOCK_PERIOD=1.0 -scemi -o bsim_dut -e mkBridge
</%doc>
.PHONY: headers 
headers:
	mkdir -p tbinclude
	<%text>${BLUESPEC_HOME}</%text>/lib/tcllib/bluespec/generateSceMiHeaders.tcl -package Bridge -bdir bdir_dut -p ../src:../scemi:+ -outdir tbinclude -enumPrefix e_ -memberPrefix m_ -aliases -vcd scemi_test.vcd -all scemi.params	

tb: cleantb 
	rm -f tb
%if _am.args.scemi:
	m4 -P ../libna/na_hostmacros.m4 ${scemi_src_list[0]} > ${scemi_src_list[0]}.postm4.cpp
	$(CXX) -o tb -D_GLIBCXX_USE_CXX11_ABI=0 -Wfatal-errors -I <%text>$(vivado_hls_path)</%text>/include -I../libs/vhls_include ${scemi_src_list[0]}.postm4.cpp ${support_src_list} tbinclude/SceMiProbes.cxx -I../tbscemi/ -I../libna/ -I../ispecs/ -Itbinclude -I<%text>${BLUESPEC_HOME}</%text>/lib/SceMi/BlueNoC -L<%text>${BLUESPEC_HOME}</%text>/lib/SceMi/BlueNoC/g++4_64 -lscemi -lpthread -ldl -lrt
%endif

.PHONY: cleantb
cleantb: 
	rm -f tb

.PHONY: clean 
clean:
	rm -rf directc* bsim_dut *.vcd tb *.hex
	rm -rf *.h *.o *.ba *.dot *.cxx *.bo mk*
	rm -rf <%text>${VLOG_GEN}</%text> bdir_dut info_dut sim_dir simdir_dut
	rm -rf tb obj
	rm -rf bsim_dut.so
	rm -f .*_

.PHONY: stage_simulation_files
stage_simulation_files: init_ compileTb_
	cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${VLOG_GEN}</%text>/*
	cp -u -t <%text>${STAGE_SIM}</%text>			../tb/tb.v
%if _am.psn.is_connect():
	cp    -t <%text>${STAGE_SIM}</%text>			../connect/*.v ../connect/*.hex
	perl -p -i -e "s/ifdef BSV_NO_INITIAL_BLOCKS/ifndef BSV_NO_INITIAL_BLOCKS/g" <%text>${STAGE_SIM}</%text>/mkOutPortFIFO.v
	rm <%text>${STAGE_SIM}</%text>/testbench_sample*.v
%endif
%if _am.psn.is_fnoc():
	cp -u -t <%text>${STAGE_SIM}</%text>			../forthnoc/*.hex
%endif	
	-cp -u -t <%text>${STAGE_SIM}</%text>			../data/*
	cp -u -t <%text>${STAGE_SIM}</%text>			${misclibbase}/libs/verilog/*.v
	cp -u -t <%text>${STAGE_SIM}</%text>			${misclibbase}/libs/verilog/Vivado/*.v
	cp -u -t <%text>${STAGE_SIM}</%text>			${misclibbase}/libs/xdc/*15ns.xdc
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO1.v
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SyncFIFO1.v
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SizedFIFO.v
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO10.v
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/RegFile*.v
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/BRAM*.v
##cp -u -t <%text>${STAGE_SIM}</%text>			<%text>${BLUESPEC_HOME}</%text>/lib/Verilog/RevertReg.v
##cp -u -t <%text>${STAGE_SIM}</%text>			${misclibbase}/libs/bsv/Bram.v

.PHONY: sim
sim: stage_simulation_files
	#iverilog  -y <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/ -y <%text>${STAGE_SIM}</%text>/ <%text>${STAGE_SIM}</%text>/tb.v -s tb && stdbuf -oL -eL vvp -n ./a.out
	cd  <%text>${STAGE_SIM}</%text> && iverilog -y . -y <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/ tb.v -s tb && stdbuf -oL -eL vvp -n ./a.out


.PHONY: scemi_vcs_generate
scemi_vcs_generate: scemi_and_link vivado_0 headers tb 

vcsb/compile.sh: scemi_vcs_generate
vcsb/elaborate.sh: stage_simulation_files ## just a trick to tie-up this file to stage_simulation_files

tracelog.db: traceDB

arctrace: tracelog.db
	./postsim_query_tracedb.py -arcs ../taskgraph/ 

.PHONY: traceDB
traceDB:
	rm -f tracelog.db
%if _am.args.simulator == 'iverilog':
	# can lead to bad concat's if the $finish happens before the last newline char is emitted
	# cat <%text>${STAGE_SIM}</%text>/*trace*.log > trace.log
	sed -e '$G' <%text>${STAGE_SIM}</%text>/*trace*.log > trace.log
%else:
	# can lead to bad concat's if the $finish happens before the last newline char is emitted
	# cat vcsb/*trace*.log > trace.log
	sed -e '$G' vcsb/*trace*.log > trace.log
%endif
	python3 ./postsim_make_tracedb.py 

.PHONY: scemi_ces
scemi_ces: vcsb/compile.sh tb
	cd vcsb && ./compile.sh && ./elaborate.sh && ./simulate.sh

.PHONY: scemi_ces_just_restage
scemi_ces_just_restage: vcsb/elaborate.sh tb
	cd vcsb && ./compile.sh && ./elaborate.sh && ./simulate.sh

scemi_s: 
	cd vcsb && ./simulate.sh
xsim_s: 
	cd xsim && ./tb.sh

tb_scemi_run: 
	until lsof -i :3375; do sleep 1; done; stdbuf -oL -eL ./tb | tee r.log

	
.PHONY: vivado
vivado: stage_simulation_files
	vivado -mode tcl -source ${behavsim_tcl}
	ln -sf project_1/project_1.sim/sim_1/behav vcsb

.PHONY: vivado_0
vivado_0: clean_vivado vivado

.PHONY: clean_vivado
clean_vivado:
	rm -rf project_1
	
.PHONY: vivado_open
vivado_open: project_1/project_1.xpr
	vivado -mode tcl project_1/project_1.xpr

.PHONY: vivado_synth
vivado_synth: project_1/project_1.xpr
	vivado -mode tcl -source ${synthesis_tcl} -tclargs <%text>${tclargs}</%text> # 'make vivado_synth tclargs="mkTop synth/synth_open/impl/impl_only/impl_open"'; 

.PHONY: vivado_impl
vivado_impl: project_1/project_1.xpr
	vivado -mode tcl -source ${synthesis_tcl} -tclargs mkTop impl


.PHONY: scemiv
scemiv: init_
	bsc <%text>${BSV_EXTRA_OPTIONS}</%text>  <%text>${BSV_COMPILE_EXTRA_MACRODEFS}</%text> -u +RTS -K32M -RTS -verilog -vdir <%text>${VLOG_GEN}</%text> -simdir simdir_dut -bdir bdir_dut -info-dir info_dut -show-range-conflict -p ../src:../scemi:+ -p +:<%text>${BLUESPEC_HOME}</%text>/lib/board_support/bluenoc/bridges:${misclibbase}/libs/bsv:${misclibbase}/libs:${relpaths1}  -elab -D SCEMI_TCP -D SCEMI_CLOCK_PERIOD=1 -D MEMORY_CLOCK_PERIOD=1 -u -g mkBridge ../scemi/Bridge.bsv
%if _am.psn.is_connect():
	cp ../connect/*.v ../connect/*.hex <%text>${VLOG_GEN}</%text>/
	perl -p -i -e "s/ifdef BSV_NO_INITIAL_BLOCKS/ifndef BSV_NO_INITIAL_BLOCKS/g" <%text>${VLOG_GEN}</%text>/mkOutPortFIFO.v
%endif
%if _am.psn.is_fnoc():
	cp -u -t <%text>${STAGE_SIM}</%text>			../forthnoc/*.hex
%endif 
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v <%text>${VLOG_GEN}</%text>/
	for f in ../scemi/main.v `cat ../scemi/support_modules_to_copy.list`; do cp -v <%text>${BLUESPEC_HOME}</%text>/$$f <%text>${VLOG_GEN}</%text>/;done
	cp -v ../scemi/main.v  <%text>${VLOG_GEN}</%text>/

.PHONY: link
link:
	scemilink --params=scemi.params --vdir=<%text>${VLOG_GEN}</%text> --verilog --simdir=<%text>${VLOG_GEN}</%text> --path=bdir_dut:+ --port=3375 mkBridge
%if _am.args.simulator == 'vcs':
	bsc <%text>${BSV_EXTRA_OPTIONS}</%text> -verilog -vsim my${_am.args.simulator} -vdir <%text>${VLOG_GEN}</%text> -D SCEMI_CLOCK_PERIOD=10.0 -D MEM_CLOCK_PERIOD=10.0 -scemi -o bsim_dut -e mkBridge
%else:
	bsc <%text>${BSV_EXTRA_OPTIONS}</%text> -verilog -vsim ${_am.args.simulator} -vdir <%text>${VLOG_GEN}</%text> -D SCEMI_CLOCK_PERIOD=10.0 -D MEM_CLOCK_PERIOD=10.0 -scemi -o bsim_dut -e mkBridge
%endif 
	##ln -sf <%text>${VLOG_GEN}</%text>/*.hex .

.PHONY: link_iverilog
link_iverilog:
	scemilink --params=scemi.params --vdir=<%text>${VLOG_GEN}</%text> --verilog --simdir=<%text>${VLOG_GEN}</%text> --path=bdir_dut:+ --port=3375 mkBridge
	bsc <%text>${BSV_EXTRA_OPTIONS}</%text> -verilog -vsim iverilog -vdir <%text>${VLOG_GEN}</%text> -D SCEMI_CLOCK_PERIOD=10.0 -D MEM_CLOCK_PERIOD=10.0 -scemi -o bsim_dut -e mkBridge
	##ln -sf <%text>${VLOG_GEN}</%text>/*.hex .


<%
# VHLS parameters
src_filelist_abspaths, top_function_list, vhls_build_dir = vhls_render_params
src_filelist_paths = [os.path.relpath(x, os.path.abspath(_am.out_simdir)) for x in src_filelist_abspaths]
#combined_cpp = src_filelist_paths[0]
def hwk_cpp_relpath(topname):
	f = os.path.join(_am.vhlswrappergen_dir, topname+".cpp") 
	r = os.path.relpath(f, _am.out_simdir)
	return r
%>

vhls_all: ${" ".join("hwk_{}".format(tf) for tf in top_function_list)}
touch_vhls_all: ${" ".join(".touch_hwk_{}".format(tf) for tf in top_function_list)}

%for top_function in top_function_list:
hwk_${top_function}: ${vhls_build_dir}/s_${top_function}/impl/ip/xilinx_com_hls_${top_function}_1_0.zip

.touch_hwk_${top_function}: 
	touch ${vhls_build_dir}/s_${top_function}/impl/ip/xilinx_com_hls_${top_function}_1_0.zip

${vhls_build_dir}/s_${top_function}/impl/ip/xilinx_com_hls_${top_function}_1_0.zip: ${" ".join(src_filelist_paths)} ${hwk_cpp_relpath(top_function)}
	vivado_hls -f ${vhls_script_tcl} -tclargs EN_${top_function} 
%endfor 



<%doc>
.PHONY: sim_ 
sim_: init_ compileTb_
	cp <%text>${VLOG_GEN}</%text>/* <%text>${STAGE_SIM}</%text>
	cp ../tb/tb.v <%text>${STAGE_SIM}</%text>/
	chmod og+r <%text>${STAGE_SIM}</%text>/tb.v
	cp ../connect/*.v ../connect/*.hex <%text>${STAGE_SIM}</%text>/
	-cp ../data/*.hex <%text>${STAGE_SIM}</%text>/
	perl -p -i -e "s/ifdef BSV_NO_INITIAL_BLOCKS/ifndef BSV_NO_INITIAL_BLOCKS/g" <%text>${STAGE_SIM}</%text>/mkOutPortFIFO.v
	rm <%text>${STAGE_SIM}</%text>/testbench_sample*.v
	ln -sf <%text>${STAGE_SIM}</%text>/*.hex .
	cp run_icarus.sh <%text>${STAGE_SIM}</%text>/
	
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v <%text>${STAGE_SIM}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO1.v <%text>${STAGE_SIM}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SyncFIFO1.v <%text>${STAGE_SIM}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SizedFIFO.v <%text>${STAGE_SIM}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO10.v <%text>${STAGE_SIM}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/RegFile*.v <%text>${STAGE_SIM}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/BRAM*.v <%text>${STAGE_SIM}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/RevertReg.v <%text>${STAGE_SIM}</%text>/
	cp ${misclibbase}/libs/bsv/Bram.v             <%text>${STAGE_SIM}</%text>/
	#cd <%text>${STAGE_SIM}</%text> && iverilog *.v && ./a.out
	#iverilog <%text>${STAGE_SIM}</%text>/*.v -s tb && vvp -n ./a.out

.PHONY: sim
sim: sim_
	iverilog <%text>${STAGE_SIM}</%text>/*.v -s tb && stdbuf -oL -eL vvp -n ./a.out

vgen: sim_
	vivado -mode tcl -source ${behavsim_tcl}
	ln -sf project_1/project_1.sim/sim_1/behav vcsb

vgenfnoc: simforthverilog_
	vivado -mode tcl -source ${behavsim_tcl}

vopen: project_1/project_1.xpr
	vivado -mode tcl project_1/project_1.xpr

vdosynth: project_1/project_1.xpr
	vivado -mode tcl -source ${synthesis_tcl} -tclargs <%text>${tclargs}</%text>


mysim: sim_
	iverilog <%text>${STAGE_SIM}</%text>/*.v -s tb && vvp -n ./a.out

simforthverilog_: init_ compileTb_
	mkdir -p <%text>${STAGE_SIM_FNOC}</%text>
	cp <%text>${VLOG_GEN}</%text>/* <%text>${STAGE_SIM_FNOC}</%text>
	cp ../tb/tb.v <%text>${STAGE_SIM_FNOC}</%text>/
	chmod og+r <%text>${STAGE_SIM_FNOC}</%text>/tb.v
	cp ../forthnoc/*hex <%text>${STAGE_SIM_FNOC}</%text>/
	-cp ../data/*.hex <%text>${STAGE_SIM_FNOC}</%text>/
	cp run_icarus.sh <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO1.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SyncFIFO1.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SizedFIFO.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO10.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/RegFile*.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/BRAM*.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/RevertReg.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp ${misclibbase}/libs/bsv/Bram.v             <%text>${STAGE_SIM_FNOC}</%text>/

simforthverilog: simforthverilog_
	cd <%text>${STAGE_SIM_FNOC}</%text> && bash run_icarus.sh && cd -

simforth: init_ compileTb_
	mkdir -p <%text>${STAGE_SIM_FNOC}</%text>
	cp <%text>${VLOG_GEN}</%text>/* <%text>${STAGE_SIM_FNOC}</%text>
	cp ../tb/tb.v <%text>${STAGE_SIM_FNOC}</%text>/
	chmod og+r <%text>${STAGE_SIM_FNOC}</%text>/tb.v
	cp ../forthnoc/*hex <%text>${STAGE_SIM_FNOC}</%text>/
	cp run_icarus.sh <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO1.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SyncFIFO1.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SizedFIFO.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO10.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/RegFile*.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog.Vivado/BRAM*.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/RevertReg.v <%text>${STAGE_SIM_FNOC}</%text>/
	cp ${misclibbase}/libs/bsv/Bram.v             <%text>${STAGE_SIM_FNOC}</%text>/
	cd <%text>${STAGE_SIM_FNOC}</%text> && bash run_icarus.sh && cd -
</%doc>

<%doc>
zync: compileTb_
	cp ../zync/*.v <%text>${VLOG_GEN}</%text>/
	cp ../connect/*.v ../connect/*.hex <%text>${VLOG_GEN}</%text>/
	perl -p -i -e "s/ifdef BSV_NO_INITIAL_BLOCKS/ifndef BSV_NO_INITIAL_BLOCKS/g" <%text>${VLOG_GEN}</%text>/mkOutPortFIFO.v

	#cp ../coregen/mk* <%text>${VLOG_GEN}</%text>/
	#cp ../coregen/zync_lt/*.v ../coregen/zync_lt/*.ngc <%text>${VLOG_GEN}</%text>
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v <%text>${VLOG_GEN}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO1.v <%text>${VLOG_GEN}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SyncFIFO1.v <%text>${VLOG_GEN}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/BRAM1.v <%text>${VLOG_GEN}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/BRAM2.v <%text>${VLOG_GEN}</%text>/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SizedFIFO.v <%text>${VLOG_GEN}</%text>/
	cd <%text>${VLOG_GEN}</%text> && iverilog *.v
</%doc>	
