#
# Makefile
# vbyk, 2017-09-06 01:02
#

all:
	@echo "Makefile needs your attention"
	g++ -o tb  tbmain.cpp nascemi.cpp tbinclude/SceMiProbes.cxx -Itbinclude -I${BLUESPEC_HOME}/lib/SceMi/BlueNoC -L${BLUESPEC_HOME}/lib/SceMi/BlueNoC/g++4_64 -lscemi -lpthread -ldl -lrt

new:
	g++ -o tb  ./data_pgmv.cpp nascemi.cpp tbinclude/SceMiProbes.cxx -Itbinclude -I${BLUESPEC_HOME}/lib/SceMi/BlueNoC -L${BLUESPEC_HOME}/lib/SceMi/BlueNoC/g++4_64 -lscemi -lpthread -ldl -lrt


# vim:ft=make
#
