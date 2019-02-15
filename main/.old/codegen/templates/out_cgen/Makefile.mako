#export PATH=$PATH:/home/users/mandardatar/local_install/iverilog/20130827/bin
#
# make headers
# make 
# make tb

default: init scemiv link
init:
	mkdir -p vlog_dut bdir_dut info_dut sim_dir simdir_dut obj
compile: init
	bsc -u +RTS -K32M -RTS -verilog -vdir vlog_dut -simdir sim_dir -bdir bdir_dut -info-dir info_dut -show-range-conflict -p ../src:%/Prelude:%/Libraries:%/Libraries/BlueNoC:../../_pelib/ -g mkTb ../src/Tb.bsv
	@echo Compilation finished
scemi: init
	bsc -u +RTS -K32M -RTS -sim -simdir simdir_dut -bdir bdir_dut -info-dir info_dut -show-range-conflict -p ../src:../scemi:+ -p +:<%text>${BLUESPEC_HOME}</%text>/lib/board_support/bluenoc/bridges -elab -D SCEMI_TCP -D SCEMI_CLOCK_PERIOD=1 -D MEMORY_CLOCK_PERIOD=1 -u -g mkBridge ../scemi/Bridge.bsv
	scemilink --sim --simdir=simdir_dut --path=bdir_dut:+ --port=3375 --params=scemi.params mkBridge
	bsc -sim -simdir simdir_dut -bdir bdir_dut -info-dir info_dut -keep-fires -D SCEMI_CLOCK_PERIOD=1.0 -D MEM_CLOCK_PERIOD=1.0 -scemi -o bsim_dut -e mkBridge
headers:
	mkdir -p tbinclude
	<%text>${BLUESPEC_HOME}</%text>/lib/tcllib/bluespec/generateSceMiHeaders.tcl -package Bridge -bdir bdir_dut -p ../src:../scemi:+ -outdir tbinclude -enumPrefix e_ -memberPrefix m_ -aliases -vcd scemi_test.vcd -all scemi.params	
tb: cleantb	
	g++ -o tb  ../tbscemi/*.cpp tbinclude/SceMiProbes.cxx -I../tbscemi/*.h -Itbinclude -I<%text>${BLUESPEC_HOME}</%text>/lib/SceMi/BlueNoC -L<%text>${BLUESPEC_HOME}</%text>/lib/SceMi/BlueNoC/g++4_64 -lscemi -lpthread -ldl -lrt

cleantb:
	rm -rf tb
clean:
	rm -rf directc* bsim_dut *.vcd tb *.hex
	rm -rf *.h *.o *.ba *.dot *.cxx *.bo mk*
	rm -rf vlog_dut bdir_dut info_dut sim_dir simdir_dut
	rm -rf tb obj
	rm -rf bsim_dut.so

sim_: init compile
	cp ../tb/tb.v vlog_dut/
	chmod og+r vlog_dut/tb.v
	cp ../connect/*.v ../connect/*.hex vlog_dut/
	rm vlog_dut/testbench_sample*.v
	ln -sf vlog_dut/*.hex .
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO1.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SizedFIFO.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO10.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/RegFile*.v vlog_dut/
	#cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/BRAM*.v vlog_dut/
	#cd vlog_dut && iverilog *.v && ./a.out
	#iverilog vlog_dut/*.v -s tb && vvp -n ./a.out
sim: sim_
	iverilog vlog_dut/*.v -s tb && stdbuf -oL -eL vvp -n ./a.out

mysim: sim_
	#cp ~/git.area/nishant/simexport/PE_lib/* vlog_dut/
	iverilog vlog_dut/*.v -s tb && vvp -n ./a.out


zync: compile
	cp ../zync/*.v vlog_dut/
	cp ../connect/*.v ../connect/*.hex vlog_dut/
	#cp ../coregen/mk* vlog_dut/
	#cp ../coregen/zync_lt/*.v ../coregen/zync_lt/*.ngc vlog_dut
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO1.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/BRAM1.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/BRAM2.v vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/SizedFIFO.v vlog_dut/
	cd vlog_dut && iverilog *.v
scemiv: init
	bsc -u +RTS -K32M -RTS -verilog -vdir vlog_dut -simdir simdir_dut -bdir bdir_dut -info-dir info_dut -show-range-conflict -p ../src:../scemi:+ -p +:<%text>${BLUESPEC_HOME}</%text>/lib/board_support/bluenoc/bridges -elab -D SCEMI_TCP -D SCEMI_CLOCK_PERIOD=1 -D MEMORY_CLOCK_PERIOD=1 -u -g mkBridge ../scemi/Bridge.bsv
	cp ../connect/*.v ../connect/*.hex vlog_dut/
	cp <%text>${BLUESPEC_HOME}</%text>/lib/Verilog/FIFO2.v vlog_dut/
link:
	scemilink --params=scemi.params --vdir=vlog_dut --verilog --simdir=vlog_dut --path=bdir_dut:+ --port=3375 mkBridge
	bsc -verilog -vsim iverilog -vdir vlog_dut -D SCEMI_CLOCK_PERIOD=10.0 -D MEM_CLOCK_PERIOD=10.0 -scemi -o bsim_dut -e mkBridge
	ln -sf vlog_dut/*.hex .

# TO RUN
# ./bsim_dut +bscvcd & 
# OR ./bsim_dut +bscvcd +bsccycle &
#
# WAIT FOR 1 SEC
# ./tb
