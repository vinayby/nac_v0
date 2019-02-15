#
# Makefile
# vbyk, 2017-03-23 15:08
#
BSV_VLIB:=/opt/Bluespec-2017.04.beta1//lib/Verilog/
BSC_OTHER_OPTIONS:=-remove-unused-modules -wait-for-license
#BSC_OTHER_OPTIONS:=
all:
	@echo "Makefile needs your attention"

prep: 
	mkdir -p bdir_dut 
	mkdir -p vlog_dut

tmisc: TestMisc.bsv prep
	bsc $(BSC_OTHER_OPTIONS) -verilog -bdir bdir_dut -vdir vlog_dut -g mkTb -p .:%/Prelude:%/Libraries:%/Libraries/BlueNoC -u TestMisc.bsv
	iverilog tb.v vlog_dut/mkTb.v 
	./a.out

r1: TestR1.bsv tb.v prep
	bsc -verilog -bdir bdir_dut -vdir vlog_dut -g mkTb -u TestR1.bsv 
	iverilog tb.v vlog_dut/mkTb.v vlog_dut/mkBRAM8_32_92.v Bram.v ${BSV_VLIB}/FIFO2.v ${BSV_VLIB}/RevertReg.v
	./a.out

r2: TestR2.bsv tb.v prep
	bsc -verilog -bdir bdir_dut -vdir vlog_dut -g mkTb -u TestR2.bsv 
	iverilog tb.v vlog_dut/mkTb.v Bram.v ${BSV_VLIB}/FIFO2.v ${BSV_VLIB}/RevertReg.v
	./a.out

r3: TestR3.bsv tb.v prep
	bsc $(BSC_OTHER_OPTIONS) -verilog -bdir bdir_dut -vdir vlog_dut -g mkTb -p .:%/Prelude:%/Libraries:%/Libraries/BlueNoC -u TestR3.bsv 
	iverilog tb.v vlog_dut/mkTb.v Bram.v ${BSV_VLIB}/FIFO2.v ${BSV_VLIB}/RevertReg.v
	./a.out

clean:
	rm -rf bdir_dut vlog_dut a.out
# vim:ft=make
#
