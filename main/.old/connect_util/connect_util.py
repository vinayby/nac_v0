#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 2016 vby
#############################vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""
Utilities to extract information from a CONNECT folder
"""
import re 
import os 

"""
CRUDE
The search pattern is different for router 0 and all other routers.
Note:
 - doesn't work for fat-tree (it has 2 cores per router) 
    - can be fixed perhaps, but left it as TODO
 - should work for 1-router-1-core scenarios 

Returns a list of tuples (a, b, c) where: 
                         out port #a of router #b goes to router #c
"""
def get_route_map(connect_folder):
    router_0_pattern = r'assign net_routers_routeTable_(\d)_rt_ifc_banks_banks_rf_\d\$ADDR_1\s=\n\s*net_routers_router_core\$out_ports_(\d)_getFlit.*;$'
    router_k_pattern = r'assign net_routers_routeTable_(\d)_rt_ifc_banks_banks_rf_\d\$ADDR_1\s=\n\s*net_routers_router_core_(\d)\$out_ports_(\d)_getFlit.*;$'
    f = os.path.join(connect_folder, 'mkNetworkSimple.v')
    with open(f) as inf:
        buf = inf.read()
        r0l = re.findall(router_0_pattern, buf, re.M)
        rkl = re.findall(router_k_pattern, buf, re.M)
        ll = [(int(goes_to), 0, int(out_port)) for (out_port, goes_to) in r0l] +  [(int(goes_to), int(of_router_k), int(out_port)) for (out_port, of_router_k, goes_to) in rkl]
        return ll

"""
Parse connect parameters file
"""
def get_connect_parameters(connect_folder):
    cpfile = os.path.join(connect_folder, 'connect_parameters.v')
    pattern = re.compile("^\`define\s(?P<pname>\w+)\s(?P<pval>\w+)$")
    f = open(cpfile)
    rl = []
    for line in f:
        match = pattern.match(line)
        if match:
            rl.append( (match.group("pname"), match.group("pval")))
    return rl

def noc_uses_credit_based_flowcontrol(connect_folder):
    f_credit = os.path.join(connect_folder, 'mkNetwork.v')
    f_peek = os.path.join(connect_folder, 'mkNetworkSimple.v')
    if os.path.exists(f_peek):
        return False
    elif os.path.exists(f_credit):
        return True
    else:
        raise ValueError(connect_folder, 'is not a CONNECT build directory')




import sys
""" e.g. 
   ./connect_util.py build.t_mesh__n_16__r_4_c_4__v_2__d_8__w_64_peek 
"""
def main():
    print(get_route_map(sys.argv[1]))
    print(get_connect_parameters(sys.argv[1]))

if __name__ == "__main__":
    main()

    


