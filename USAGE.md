# Usage examples

## Simple Example 1
- In the folder `examples/simple_ex1`, the files `cfg` and `test.na` make up the first set of design specification files while the *.cpp files are secondary/generated/updated later.
- The `noc` option in `cfg` points to a CONNECT (Or Forth) NoC folder (the user may generate one from [here](users.ece.cmu.edu/~mpapamic/connect/
)) 
- The generated folder `1_sourcehls` has the HLS source of the kernels (here, already filled-in).
The contents of the `1_sourcehls` directory are generated on first run.

```bash
$ cd examples/simple_ex1
$ tree -L 1
├── 1_sourcehls
├── cfg
├── main.cpp          # sw-code for host() task for RTL hw-sw co simulation
├── natask_host.cpp   # sw-code for host() task for MPI simulation
└── test.na           # main .na specification
$ nac -c cfg test.na
##Command Line Args:   -c cfg test.na
##Config File (cfg):
##	noc:               /path/to/_nocs/build.t_mesh__n_16__r_4_c_4__v_2__d_4__w_64_peek_vlinks/
##	outdir:            1_out
##	vhlswrappers:      1_sourcehls
##	simulator:         vcs
##	no-task-info:      true
##	scemi:             true
##	runtime-src-list:  ['main.cpp']
##	mpi-src-list:      ['natask_host.cpp']
##	simv:              state-entry-exit
##Defaults:
##	--simulator-simlib-path:/home/vinay/.config/nac/simlib_SIMULATOR
##	--scemi-src-list:  []
##	--either-or-lateral-io:True

##> generated		 1_out/bviwrappers/Plus1.bsv
##> generated		 1_out/bviwrappers/Plus1f.bsv
##nochange, untouched	 1_sourcehls/vhls_natypes.h
##nochange, untouched	 1_sourcehls/combined.cpp
##nochange, untouched	 1_sourcehls/vhls_script.tcl
##> generated		 1_out/tcl/create_project.tcl
##> generated		 1_out/tcl/open_and_synthesize.tcl
##> generated		 1_out/src/Tasks.bsv
##> generated		 1_out/src/CnctBridge.bsv
##> generated		 1_out/src/NetworkSimple.bsv
##> generated		 1_out/src/NTypes.bsv
##> generated		 1_out/src/Top.bsv
##> generated		 1_out/src/NATypes.bsv
##> generated		 1_out/src/Tb.bsv
##> generated		 1_out/tcl/vhls_script.tcl
##> generated		 1_out/tbscemi/scemi_na_util.h
```

## Example 1
```bash
$ cd minimal0
$ tree
├── 1_sourcehls_ready         # ignore at this stage
├── cfg                       
├── main.cpp                  # sw-code for the host() task for RTL cosimulation
├── natask_host.cpp           # sw-code for the host() task for MPI simulation 
|                             #    both are `essentially' identical (see the `diff'?)
└── test.na                   # main .na code

$ nac -c cfg test.na 
Command Line Args:   -c cfg test.na
Config File (cfg):
  noc:               _nocs/build.t_mesh__n_16__r_4_c_4__v_2__d_4__w_64_peek_vlinks/
  outdir:            1_out
  vhlswrappers:      1_sourcehls
  simulator:         vcs
  no-task-info:      true
  buffered-sr-ports: true
  scemi:             true
  runtime-src-list:  ['main.cpp']
  mpi-src-list:      ['natask_host.cpp']
  simv:              state-entry-exit
Defaults:
  --simulator-simlib-path:/home/vinay/.config/nac/simlib_SIMULATOR
  --scemi-src-list:  []

nochange, untouched      1_out/bviwrappers/Plus1.bsv
nochange, untouched      1_out/bviwrappers/Plus1f.bsv
> generated              1_sourcehls/vhls_natypes.h
> generated              1_sourcehls/plus1.cpp          # HLS kernel template 1 (to be filled in)
> generated              1_sourcehls/plus1f.cpp         # HLS kernel template 2 (to be filled in)
> generated              1_sourcehls/combined.cpp
> generated              1_sourcehls/vhls_script.tcl
nochange, untouched      1_out/tcl/create_project.tcl
nochange, untouched      1_out/tcl/open_and_synthesize.tcl
nochange, untouched      1_out/src/Tasks.bsv
nochange, untouched      1_out/src/CnctBridge.bsv
nochange, untouched      1_out/src/NetworkSimple.bsv
nochange, untouched      1_out/src/NTypes.bsv
nochange, untouched      1_out/src/Top.bsv
nochange, untouched      1_out/src/NATypes.bsv
nochange, untouched      1_out/src/Tb.bsv
nochange, untouched      1_out/tb/tb.v
nochange, untouched      1_out/sim/Makefile
nochange, untouched      1_out/tcl/vhls_script.tcl
nochange, untouched      1_out/tbscemi/scemi_na_util.h
nochange, untouched      1_out/scemi/SceMiLayer.bsv

$ ### could copy over the ready HLS kernels from the *_ready folder
$ cp 1_sourcehls_ready/plus1*cpp 1_sourcehls/
```
### MPI simulation

```bash
$ nac -c cfg test.na -mpi
Command Line Args:   -c cfg test.na -mpi
Config File (cfg):
  noc:               _nocs/build.t_mesh__n_16__r_4_c_4__v_2__d_4__w_64_peek_vlinks/
  outdir:            1_out
  vhlswrappers:      1_sourcehls
  simulator:         vcs
  no-task-info:      true
  buffered-sr-ports: true
  scemi:             true
  runtime-src-list:  ['main.cpp']
  mpi-src-list:      ['natask_host.cpp']
  simv:              state-entry-exit
Defaults:
  --simulator-simlib-path:/home/vinay/.config/nac/simlib_SIMULATOR
  --scemi-src-list:  []

nochange, untouched      1_out/bviwrappers/Plus1.bsv
nochange, untouched      1_out/bviwrappers/Plus1f.bsv
nochange, untouched      1_sourcehls/vhls_natypes.h
nochange, untouched      1_sourcehls/combined.cpp
nochange, untouched      1_sourcehls/vhls_script.tcl
nochange, untouched      1_out/tcl/create_project.tcl
nochange, untouched      1_out/tcl/open_and_synthesize.tcl
> generated              1_out/mpimodel/mpimodel_main.cpp
> generated              1_out/mpimodel/mpimodel.h
> generated              1_out/mpimodel/Makefile
> generated              1_out/mpimodel/rewrapped_hwkernels.cpp
```

```bash
$ cd 1_out/mpimodel/
$ make
# which does, e.g.:
# m4 -P ../libna/na_hostmacros.m4 natask_host.cpp > natask_host.postm4.cpp 
# mpic++ -Wfatal-errors -o empi -I /include/ -I../libs/vhls_include -I ../libna -I ../../1_sourcehls mpimodel_main.cpp natask_host.postm4.cpp
$ make run 
# which does:
# mpirun -np 5 --output-filename 1out ./empi

###---------- this is a deliberate abort----------------------
MPI_ABORT was invoked on rank 1 in communicator MPI_COMM_WORLD 
with errorcode 0.
###-----------------------------------------------------------
```

```bash
$ tree # output from each rank go to these files 
.
├── 1out.1.0 
├── 1out.1.1 
├── 1out.1.2
├── 1out.1.3
├── 1out.1.4
# na task_id (NoC port_id) to rank_id mapping:
# cat ../sim/taskmap.json --> host is rank 1 (logfile: 1out.1.1), echo is rank 2 (logfile: 1out.1.2), etc., 
```

$ cat 1out.1.1 
```bash
start:host na_task_id=10 rank=1
->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
->	xf=XF { v: 000001.2 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 01.09999 }
->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }
->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
->	xf=XF { v: 1.200000 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 01.09999 }
->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }
->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
->	xf=XF { v: 1.200000 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 01.09999 }
->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }
->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
->	xf=XF { v: 1.200000 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 01.09999 }
->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }
[0.00457907] end:host na_task_id=10 rank=1

```
### RTL-cosimulation

```bash
$ # OPEN two terminals (or use tmux or screen)

### TERMINAL-1

TERMINAL 1$ cd 1_out/sim/
TERMINAL 1$ source /opt/Xilinx/Vivado/2016.4/settings64.sh
TERMINAL 1$ make scemi_ces
# < SYNTHESIS AND SIMULATION OUTPUT NOT SHOWN >
# This simulation will end when TERMINAL-2 software program exits

### TERMINAL-2

TERMINAL 2$ make tb_scemi_run
until lsof -i :3375; do sleep 1; done; stdbuf -oL -eL ./tb | tee r.log
# when TERMINAL 1 simulation starts, this will execute

COMMAND     PID  USER   FD   TYPE   DEVICE SIZE/OFF NODE NAME
main_simv 17728 vinay   32u  IPv4 16316676      0t0  TCP *:3375 (LISTEN)
.->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
.->	xf=XF { v: 000001.2 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 02.19998 }
.->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
.->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }
.->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
.->	xf=XF { v: 1.200000 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 02.19998 }
.->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
.->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }
.->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
.->	xf=XF { v: 1.200000 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 02.19998 }
.->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
.->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }
.->	x=X { v: 0000x0b5 }
<-	rx=X { v: 0000x119 }
.->	xf=XF { v: 1.200000 a: 000000x1 b: <V 1, 1, 1, 1, >, c: <V 1.200000 1.200000 1.200000 >, e: <V 1.200000 1.200000 >, d: 00000001 f: 01.09999 }
<-	rxf=XF { v: 2.300000 a: 000000x2 b: <V 2, 2, 2, 2, >, c: <V 2.300000 2.300000 2.300000 >, e: <V 2.300000 2.300000 >, d: 00000002 f: 02.19998 }
.->	ws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
<-	rws=WS { weight: 01.29999 x: 00180.77 y: 00106.83 }
.->	p=Pixel { rgb: <V 65, 66, 67, >, }
<-	rp=Pixel { rgb: <V 65, 66, 67, >, }

TERMINAL 2$ # To stop, <control-C> here, to terminate the simulation in TERMINAL 1 (not the other way around)
```

```bash
### Now, going back to TERMINAL 1

TERMINAL 1$ cd vcsb/ # a symlink to vcs/ simulation directory
TERMINAL 1$ ls -1|grep log
   elaborate.log
   log_echof_node.0.debug.log
   log_echof_node.0.trace.log
   log_echo_node.5.debug.log
   log_echo_node.5.trace.log
   log_FromNetworkTask_echof_node.0.debug.log
   log_FromNetworkTask_echof_node.0.trace.log
   log_FromNetworkTask_echo_node.5.debug.log
   log_FromNetworkTask_echo_node.5.trace.log
   log_FromNetworkTask_sink0_node.1.debug.log
   log_FromNetworkTask_sink0_node.1.trace.log
   log_sink0_node.1.debug.log
   log_sink0_node.1.trace.log
   log_ToNetworkTask_echof_node.0.debug.log
   log_ToNetworkTask_echof_node.0.trace.log
   log_ToNetworkTask_echo_node.5.debug.log
   log_ToNetworkTask_echo_node.5.trace.log
   log_ToNetworkTask_sink0_node.1.debug.log
   log_ToNetworkTask_sink0_node.1.trace.log
   scemilink.vlog_fragment
   simulate.log
   vlogan.log

TERMINAL 1$ # ^^^^^ simulation trace logs 
TERMINAL 1$ # cd ../ # need to pass --event-trace/-evts switch to nac though. 
TERMINAL 1$ # make traceDB # creates a DB out of the trace files; more on this later
```

## Particle-filter based visual object tracking
- shortly

## Matrix-vector multiplication
- shortly
