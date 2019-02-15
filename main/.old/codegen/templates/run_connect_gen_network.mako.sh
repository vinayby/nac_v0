#! /bin/sh
#
# run_connect_gen_network.mako.sh
#

./scripts/connect_gen_network --topology=mesh \
                               --num_routers=4 \
                               --num_vcs=4 \
                               --flit_buffer_depth=8 \
                               --flit_data_width=32 




