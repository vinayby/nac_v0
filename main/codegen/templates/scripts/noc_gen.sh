#! /bin/sh
#
# noc_gen.sh

TOPOLOGY=$1
FWIDTH=$2
VCS=4

connect_gen_network -t mesh -n 4 -r 2 -c 2 -v 4 -d 8 -w 64 --flow_control_type=peek 
