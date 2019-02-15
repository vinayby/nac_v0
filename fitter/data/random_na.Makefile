#
# Makefile
#

all:
	@echo "Makefile needs your attention"

nac: rnd.na cfg 
	nac -c cfg rnd.na -tg
	nac -c cfg rnd.na 
	nafitter -g 1_out/taskgraph/ -viz
	@mv G.dot.png G.png
	rm G.dot*

fitdefault: fitf1 fitf1_L fitfmesh fitf1_msgsched2
gendefault: 		  gen_f1 gen_f1_L gen_fmesh
simdefault: sim0   simf1   simf1_L  simfmesh

fitf1: 
	nafitter -g 1_out/taskgraph/ -f1 -o fitf1 --objective both
	nafitter -g 1_out/taskgraph/ -f1 -o fitf1_energy --objective energy
	nafitter -g 1_out/taskgraph/ -f1 -o fitf1_makespan --objective makespan

fitf1_L: 
	nafitter -g 1_out/taskgraph/ -f1 -o fitf1_L --objective both -f1opts Lboth 
	nafitter -g 1_out/taskgraph/ -f1 -o fitf1_L_energy --objective energy -f1opts Lboth 
	nafitter -g 1_out/taskgraph/ -f1 -o fitf1_L_makespan --objective makespan -f1opts Lboth 

fitf1_msgsched2:
	nafitter -g 1_out/taskgraph/ -f1msgsched-2phase 1_out/taskgraph/fitf1/map_t2r.json -o fitf1msg2 --objective makespan 

fitfmesh: 
	nafitter -g 1_out/taskgraph/ -fmesh -o fitfmesh

gen_f1: 
	nac -c cfg -map 1_out/taskgraph/fitf1/map_t2r.json -odir 1_out_f1 rnd.na 
	nac -c cfg -tg -odir 1_out_f1 rnd.na 

gen_f1_L: 
	nac -c cfg -map 1_out/taskgraph/fitf1_L/map_t2r.json -odir 1_out_f1_L rnd.na 
	nac -c cfg -tg -odir 1_out_f1_L rnd.na 

gen_fmesh: 
	nac -c cfg -map 1_out/taskgraph/fitfmesh/map_t2r.json -odir 1_out_fmesh rnd.na
	nac -c cfg -tg -odir 1_out_fmesh rnd.na 

gen_f1msgsched2: rnd_opt.na
	nac -c cfg -map 1_out/taskgraph/fitf1/map_t2r.json -odir 1_out_f1_msgsched2 rnd_opt.na 
	nac -c cfg -tg -odir 1_out_f1_msgsched2 rnd_opt.na 

sim0: 1_out/sim/Makefile
	make -C $(<D) sim
	make -C $(<D) arctrace | tee $(<D)/Xarcs.log

simf1: 1_out_f1/sim/Makefile
	make -C $(<D) sim
	make -C $(<D) arctrace | tee $(<D)/Xarcs.log

simf1_L: 1_out_f1_L/sim/Makefile
	make -C $(<D) sim
	make -C $(<D) arctrace | tee $(<D)/Xarcs.log

simfmesh: 1_out_fmesh/sim/Makefile
	make -C $(<D) sim
	make -C $(<D) arctrace | tee $(<D)/Xarcs.log

simf1msgsched2: 1_out_f1_msgsched2/sim/Makefile
	make -C $(<D) sim
	make -C $(<D) arctrace | tee $(<D)/Xarcs.log

.PHONY: showsimtimes 
showsimtimes:
	cd 1_out/sim/ && ./query_tracedb.py -lastbarrier
	cd 1_out_f1/sim/ && ./query_tracedb.py -lastbarrier
	cd 1_out_f1_L/sim/ && ./query_tracedb.py -lastbarrier
	cd 1_out_fmesh/sim/ && ./query_tracedb.py -lastbarrier
	cd 1_out_f1_msgsched2/sim/ && ./query_tracedb.py -lastbarrier
showcosts:
	grep Runtime 1_out/taskgraph/fit*/gurobi.log
	@echo fitf1
	nafitter -g 1_out/taskgraph/ -showcost 1_out/taskgraph/fitf1/map_t2r.json
	nafitter -g 1_out/taskgraph/ -showcost 1_out/taskgraph/fitf1_energy/map_t2r.json
	nafitter -g 1_out/taskgraph/ -showcost 1_out/taskgraph/fitf1_makespan/map_t2r.json
	@echo fitf1_L 
	nafitter -g 1_out/taskgraph/ -showcost 1_out/taskgraph/fitf1_L/map_t2r.json
	nafitter -g 1_out/taskgraph/ -showcost 1_out/taskgraph/fitf1_L_energy/map_t2r.json
	nafitter -g 1_out/taskgraph/ -showcost 1_out/taskgraph/fitf1_L_makespan/map_t2r.json
	@echo fitfmesh 
	nafitter -g 1_out/taskgraph/ -showcost 1_out/taskgraph/fitfmesh/map_t2r.json
	@echo default
	nafitter -g 1_out/taskgraph/ -showcost 1_out/sim/taskmap.json



# vim:ft=make
#
    
