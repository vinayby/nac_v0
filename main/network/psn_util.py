#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 2016 vby
#############################vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""
Utilities to extract information from a CONNECT folder
"""
import pdb
import re 
import os 
import glob

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
Detect NoC type 
"""
def detect_noc_type(nocpath):
    markers1 = ['connect_parameters.v', 'mkNetwork.v', 'mkNetworkSimple.v', 'connect_parameters.json']
    markers2 = ['params.json', 'fnoc_parameters.json']
    le1 = list(map(os.path.exists, [os.path.join(nocpath, fmarker) for fmarker in markers1]))
    le2 = list(map(os.path.exists, [os.path.join(nocpath, fmarker) for fmarker in markers2]))
    if le1[0] or le1[3]:
        subtype = None 
        if le1[2]:
            subtype = 'peek'
        if le1[1]:
            subtype = 'credit'
        return ('connect', subtype, os.path.join(nocpath, markers1[0]))
    if le2[0] or le2[1]:
        return ('fnoc', '_reserved_', os.path.join(nocpath, markers2[1] if le2[1] else markers2[0]))

"""
For connect_parameters.v
"""
def parse_connect_parameters(parameters_v):
    pattern = re.compile("^\`define\s(?P<pname>\w+)\s(?P<pval>\w+)$")
    f = open(parameters_v)
    rl = []
    for line in f:
        match = pattern.match(line)
        if match:
            rl.append( (match.group("pname"), match.group("pval")))
    return rl
    

"""
Parse FNOC parameters file
"""
def get_noc_parameters(nocpath):
    def loadjson(filename):
        import json
        with open(filename, 'r') as fh:
            return json.load(fh)
    params = loadjson(os.path.join(nocpath, 'params.json'))
    rl = []
    for k, v in params.items():
        rl.append((k, v))
    return rl
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

"""
    crude
"""
def is_topology_mesh(folder):
    if detect_noc_type(folder)[0] == 'fnoc':
        return False # not worth it
    elif detect_noc_type(folder)[0] == 'connect':
        count = 0
        for filename in glob.glob(os.path.join(folder,'*.hex')):
            if os.path.basename(filename).startswith('mesh_'):
                count += 1
        cp = get_connect_parameters(folder)
        nrouters = 0
        for k, v in cp:
            if k == 'NUM_ROUTERS':
                nrouters = int(v)

        if count == nrouters:
            return True
        elif count:
            print("This shouldn't be happening. \n corrupt {}? ".format(folder))
        
        return False
    else:
        print('NoC folder unrecognizable')




"""
Read from the .routing and .topology files when available.
Otherwise, we extract the information from the generated network.
 - routing from the hex files
 - topology from mkNetwork.v or mkNetworkSimple.v
"""
def read_topology_and_routing_info(folder):
    if detect_noc_type(folder)[0] == 'fnoc':
        return read_fnoc_rtables_rpaths(folder)
    elif detect_noc_type(folder)[0] == 'connect':
        connect_folder = folder
        return generate_meshNOC_from_routingTables(connect_folder)
    else:
        print('NoC folder unrecognizable')


"""
Default CONNECT folders do not have the .routing/.topology files as a part of the downloaded archive. 
This is a QnD way to extract the information from the generated Verilog files.
"""
def generate_meshNOC_from_routingTables(folder):
            
    def get_route_map(connect_folder):
        router_0_pattern = r'assign net_routers_routeTable_(\d+)_rt_ifc_banks_banks_rf_\d+\$ADDR_1\s=\n\s*net_routers_router_core\$out_ports_(\d+)_getFlit.*;$'
        router_k_pattern = r'assign net_routers_routeTable_(\d+)_rt_ifc_banks_banks_rf_\d+\$ADDR_1\s=\n\s*net_routers_router_core_(\d+)\$out_ports_(\d+)_getFlit.*;$'
        router_k0_pattern = r'assign net_routers_routeTable_rt_ifc_banks_banks_rf_\d+\$ADDR_1\s=\n\s*net_routers_router_core_(\d+)\$out_ports_(\d+)_getFlit.*;$'
    
        noc_top_v = 'mkNetworkSimple.v'
        if noc_uses_credit_based_flowcontrol(connect_folder):
            noc_top_v = 'mkNetwork.v'
        f = os.path.join(connect_folder, noc_top_v)
        with open(f) as inf:
            buf = inf.read()
            r0l = re.findall(router_0_pattern, buf, re.M)
            rkl = re.findall(router_k_pattern, buf, re.M)
            rk0 = re.findall(router_k0_pattern, buf, re.M)
            ll = [(int(goes_to), 0, int(out_port)) for (out_port, goes_to) in r0l] + [(int(out_port), int(of_router_k), 0) for (of_router_k, out_port) in rk0] + [(int(goes_to), int(of_router_k), int(out_port)) for (out_port, of_router_k, goes_to) in rkl]
            return ll

    routingTable={} 
    numRouters=0
    for filename in glob.glob(os.path.join(folder,'*.hex')):
        B=re.findall(r'\d+.hex',filename)
        index=int(B[0].split('.')[0])
        if index not in routingTable:
            routingTable[index]={}
        f=open(filename,'r')
        addr=0
        while True:
            line=f.readline()
            if not line:
                break
            routingTable[index][addr]=int(line)
            addr+=1
        f.close()
    
    numRouters=addr
    
    temp=get_route_map(folder)
    nextRouter={i:{} for i in range(numRouters)}
    for tuple in temp:
        out_port=tuple[0]
        router=tuple[1]
        nRouter=tuple[2]
        nextRouter[router][out_port]=nRouter
    
    def findHops(source,dest):
        hop=0
        path=[]
        while source!=dest:
            hop+=1
            nRouter=nextRouter[source][routingTable[source][dest]]
            path.append((source,nRouter))
            source=nRouter
        return hop,path      
    
    #Create dictionary containg hop lengths from i to j
    dist={i:{j:0 for j in range(numRouters)} for i in range(numRouters)}
    path={i:{j:[] for j in range(numRouters)} for i in range(numRouters)}
    
    for i in range(numRouters):
        for j in range(numRouters):
            dist[i][j],path[i][j]=findHops(i,j)
    


    #Make Tile Name List dictionary,distance matrix,no of tiles(M)
    NOC_NameList={str(i):i for i in range(numRouters)}
    return NOC_NameList,dist,path,numRouters

def read_fnoc_rtables_rpaths(folder):
    def parse_topology_specs(topo_specs):
        rl_pattern =  r'RouterLink R(\d+):(\d+) -> R(\d+):(\d+)'
        s_port_pattern = r'SendPort (\d+) -> R(\d+):(\d+)'
        r_port_pattern = r'RecvPort (\d+) -> R(\d+):(\d+)'
        ls = []
        lr = []
        lrl = []
        import re
        for line in open(topo_specs, 'r'):    
            rl = re.findall(rl_pattern, line, re.M)
            s =  re.findall(s_port_pattern, line, re.M)
            r =  re.findall(r_port_pattern, line, re.M)
            if rl:
                lrl.append(rl[0])
            if s:
                ls.append(s[0])
            if r:
                lr.append(r[0])
            if not ( r or s or rl):
                print("{} malformed ".format(topo_specs))
                
        return (ls, lr, lrl)
    def parse_routing_specs(routing_specs):
        route_pattern = r'R(\d+): (\d+) -> (\d+)'
        import re
        rtable = {}
        rl = []
        for line in open(routing_specs, 'r'):
            r = re.findall(route_pattern, line, re.M)
            if r:
                key, addr, port = map(int, r[0])
                if key not in rtable:
                    rtable[key] = {}
                rtable[key][addr] = port
        return rtable
        
           
    def get_route_map(folder):
        """
        generates list of (portX, onRouter, goesTo_routerY)
        """
        ls, lr, lrl = parse_topology_specs(os.path.join(folder, 'net.topology'))
        return [(int(portX), int(onR), int(rY)) for onR, portX, rY, ryport in lrl]
        
    routingTable = parse_routing_specs(os.path.join(folder, 'net.routing'))
    numRouters=len(routingTable)
    
    temp=get_route_map(folder)
    nextRouter={i:{} for i in range(numRouters)}
    for tuple in temp:
        out_port=tuple[0]
        router=tuple[1]
        nRouter=tuple[2]
        nextRouter[router][out_port]=nRouter
    
    def findHops(source,dest):
        hop=0
        path=[]
        while source!=dest:
            hop+=1
            nRouter=nextRouter[source][routingTable[source][dest]]
            path.append((source,nRouter))
            source=nRouter
        return hop,path      
    
    #Create dictionary containg hop lengths from i to j
    dist={i:{j:0 for j in range(numRouters)} for i in range(numRouters)}
    path={i:{j:[] for j in range(numRouters)} for i in range(numRouters)}
    
    for i in range(numRouters):
        for j in range(numRouters):
            dist[i][j],path[i][j]=findHops(i,j)


    #Make Tile Name List dictionary,distance matrix,no of tiles(M)
    NOC_NameList={str(i):i for i in range(numRouters)}
    return NOC_NameList,dist,path,numRouters





import sys
""" e.g. 
   ./connect_util.py build.t_mesh__n_16__r_4_c_4__v_2__d_8__w_64_peek 
"""
def main():
    print(get_route_map(sys.argv[1]))
    print(get_connect_parameters(sys.argv[1]))

if __name__ == "__main__":
    main()

    


