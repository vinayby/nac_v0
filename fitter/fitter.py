#! /usr/bin/env python
# -*- coding: utf-8 -*-
""" [2017] vbyk
"""
################## vim:fenc=utf-8 tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import os,errno
import math
import re
import json
from intervaltree import Interval, IntervalTree
try:
    import Queue as queue 
except ImportError:
    import queue 

import pdb
from optparse import OptionParser
from argparse import ArgumentParser

PACKAGE_PARENT = '..'
SCRIPT_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(SCRIPT_DIR, PACKAGE_PARENT)))
# sys.path.insert(0, os.getenv('GUROBI751',"/opt/gurobi751/linux64/build/lib.linux-x86_64-2.7")) 

def loadjson(filename):
    import json
    try:
        with open(filename, 'r') as fh:
            return json.load(fh)
    except Exception as e:
        raise e

from main.network import psn_util 
from nasm import nasm
from nasm import nasm_msgsched
from nasm import na_meshILPv1
import networkx as nx
#------------ util -------------------------------------------
import math
def meshprint(matrix):
	s = [[str(e) for e in row] for row in matrix]
	lens = [max(map(len, col)) for col in zip(*s)]
	fmt = '\t'.join('{{:{}}}'.format(x) for x in lens)
	table = [fmt.format(*row) for row in s]
	return '\n'.join(table)

def chunks(l, n):
    """Yield successive n-sized chunks from l."""
    for i in range(0, len(l), n):
        yield l[i:i + n]

def trymkdir(dirname):
    try:
        os.mkdir(dirname)
    except OSError as e:
        if e.errno == errno.EEXIST:
            pass
#-------------------------------------------------------------
def write_dot(G, filename):
    try:
        import pygraphviz
        from networkx.drawing.nx_agraph import write_dot
    except ImportError:
        try:
            import pydotplus
            from networkx.drawing.nx_pydot import write_dot
        except ImportError:
            print("\nBoth pygraphviz and pydotplus were not found\n")
            raise
    if len(nx.get_node_attributes(G, 'd')) == len(G): # all nodes have the attribute
        rename_map = {n: '{}\n{}'.format(n, G.nodes[n]['d']) for n in G.nodes()}
        H = nx.relabel_nodes(G, rename_map) # returns a copy by default
        write_dot(H, filename)
    else:
        write_dot(G, filename)
    try:
        import pydot 
        oimg = pydot.graph_from_dot_file(filename)
        oimg = oimg[0].create(prog='dot', format='png')
        with open(filename+'.png', 'w') as fh:
            fh.write(oimg)
    except ImportError:
        print('INFO: Install pydot to also have a .png generated')

    
def remove_cycles_temporary(G):
    def reverse_edge(a,b):
        attrib = G.edges[a, b]
        G.remove_edge(a,b)
        G.add_edge(b,a,attrib)
    
    count = 0
    scl = list(nx.simple_cycles(G))
    while scl:
        count = count + 1
        c = scl[0] # remove cycles one at a time
        # len(2) or more, just reverse c[0], c[1]
        print("reversing edge ", c)
        reverse_edge(c[0], c[1])
        scl = list(nx.simple_cycles(G))
    return count


def to_graph_with_send_arcs_made_dummy_tasks(G_):
    G = G_.copy()
    # tasks with multiple outgoing arcs
    outgoing_arcs_by_task = {}
    for task in G.nodes():
        outgoing_arcs_by_task[task] = [edge for edge in G.edges() if edge[0] == task]
    
    # list of task clusters after introducing the dummy send nodes
    task_clusters = {} # real : [dummy...]
    for task, outarcs in outgoing_arcs_by_task.items():
        if len(outarcs)>1:
            task_clusters[task] = []
            for a, b in outarcs:
                G.add_edge(a, a+b, label=0, volume=0)
                G.add_edge(a+b, b, label=G.edges[a, b]['volume'], volume = G.edges[a, b]['volume'])
                G.remove_edge(a, b)
                task_clusters[task].append(a+b)
    return G, task_clusters


def read_post_na_graph(filename, specs, merged=True):
    lines=[]
    for line in open(filename, 'r'):
        l = line.strip()
        # ignore empty and comment lines
        if l and not l.startswith('#'):
            lines.append(l.rstrip())
    nnodes = int(lines[0])
    nedges = int(lines[1])
    G = nx.DiGraph()
    for edge in lines[3:]:
        if merged:
            src, dst, val1 = edge.split()
            G.add_edge(src, dst, label=val1, volume=val1)
        else:
              src, dst, val1,   src_lno, src_lvl, src_stmtname,     dst_lno, dst_lvl, dst_stmtname = edge.split()
              src = '{}:{}:{}'.format(src,src_stmtname,src_lno)
              dst = '{}:{}:{}'.format(dst,dst_stmtname,dst_lno)
              G.add_edge(src, dst, label=(val1), volume=(val1), 
                      slineno=src_lno, dlineno=dst_lno, 
                      slevel=src_lvl, dlevel=dst_lvl,
                      sname=src_stmtname, dname=dst_stmtname)
    if specs:
        # assign node attributes
        kdurations_dict = {tn: d['duration']  for tn, [d] in specs['task_kernels'].items()}
        nx.set_node_attributes(G, kdurations_dict, 'd')

    
    return G


def update_G_from_tracelog(G, tracelog_db, startpos, endpos):
    import sqlite3
    file_taskmap  = 'taskmap.json'
    file_lineinfo = '1_out/ispecs/line_annotations.json'
    g_conn = sqlite3.connect('tracelog.db')
    g_dbc = g_conn.cursor()
    g_taskmap = loadjson(file_taskmap)
    na_lineinfo  = loadjson(file_lineinfo)
    g_taskmap_inv = {v: k for k, v in g_taskmap.items()}
    stmt_names          = g_dbc.execute('SELECT DISTINCT name FROM natrace').fetchall()
    stmt_names          = [n[0] for n in stmt_names]
    stmt_name_shorthand = {n[0]:n for n in stmt_names}
    class StmtLineInfo(object):
        def __init__(self, taskname, lno, lvl, name=''):
            self._taskname = taskname
            self._tid = None
            if taskname:
                self._tid = g_taskmap[taskname] if ':' not in taskname else g_taskmap[taskname.split(':')[0]]
            self._lno = lno
            self._lvl = lvl
            self._name = name
        def __repr__(self):
            return '{}:l{}:d{}_{}'.format(self._taskname, self._lno, self._lvl, self._name)
    def query_template1(stmt, top_nbottom, tick_upperlimit=sys.maxint, tick_lowerlimit=0):
        if stmt._tid:
            q="SELECT tick FROM natrace WHERE name='{}' and lno={} and lvl={} and tid={} and ev_ts='{}' and tick >= {} and tick <= {} ORDER BY tick".format(stmt._name, stmt._lno, stmt._lvl, stmt._tid, top_nbottom, tick_lowerlimit, tick_upperlimit)
        else:
            q="SELECT tick FROM natrace WHERE name='{}' and lno={} and lvl={} and            ev_ts='{}' and tick >= {} and tick <= {} ORDER BY tick".format(stmt._name, stmt._lno, stmt._lvl,            top_nbottom, tick_lowerlimit, tick_upperlimit)
        r = g_dbc.execute(q).fetchall()
        return r

    # find upper_limit statement
    def find_statement_info_by_lno(lno, stmt_name, taskname=None):
        lno = str(lno)
        if lno in na_lineinfo:
            for e in na_lineinfo[lno]: # find stmt that matches name
                if stmt_name == e[2]:
                    print(e)
                    return StmtLineInfo(taskname, *e)
    def expand_(a):
        """ [taskname:](stmt_shorthand|stmt_fullname):line_no --> StmtLineInfo """
        ll = a.split(':')
        sh, lno = ll[-2:] # last two items
        taskname = None
        name = sh
        if len(sh) == 1:
            name = stmt_name_shorthand[sh]
        if len(ll) == 3:
            taskname = ll[0]
        if lno in na_lineinfo:
            for e in na_lineinfo[lno]: # find stmt that matches name
                if name == e[2]:
                    return StmtLineInfo(taskname, *e)
        else:
            # search ahead for first match with stmt_name
            #   - some statements take on line number of first nearest (below) stmt
            #   - a parsing quirk
            def search_ahead(lno, name):
                lno = int(lno)
                while True:
                    lno = lno + 1
                    if str(lno) in na_lineinfo:
                        for stmt_e in na_lineinfo[str(lno)]:
                            if stmt_e[2] == name:
                                return stmt_e
            e = search_ahead(lno, name)
            return StmtLineInfo(taskname, *e)
        print("line specification incorrect, quitting {} {} {} \n".format(taskname, name, lno))
#         sys.exit(1)
        pass
    
    upper_limit = sys.maxint
    lower_limit = 0
    if endpos:
        q = query_template1(expand_(endpos), 'bottom' )
        upper_limit = q[0][0] # first instance
    if startpos:
        q = query_template1(expand_(startpos), 'top' )
        lower_limit = q[0][0] # first instance

    timeline_used_stmt = {}
    for src, dst, ddict in G.edges(data=True):
        if int(ddict['slineno']) == 0 or int(ddict['dlineno']) == 0:
            continue
        sI = expand_(src)
        dI = expand_(dst)
        #sI = StmtLineInfo(src, ddict['slineno'], ddict['slevel'], ddict['sname'])
        #dI = StmtLineInfo(dst, ddict['dlineno'], ddict['dlevel'], ddict['dname'])
        if src in timeline_used_stmt:
            lower_limit = timeline_used_stmt[src]
        qst = query_template1(sI, 'top', upper_limit, lower_limit)
        qdt = query_template1(dI, 'bottom', upper_limit, lower_limit)
        if len(qst) == 0 or len(qdt) == 0:
            print('false-arc {} -- {}'.format( src, dst ))
        elif not ( 0 == len(qst)-len(qdt) ):
            try:
                #if qst and qst[len(qdt)-1]:
                timeline_used_stmt[src] = qst[len(qdt)][0]
            except Exception as e:
                print(e, ":: len(qst) = {}, len(qdt) = {} {}---=>---{}".format( len(qst), len(qdt), src, dst))
            print('LENGTHS src:{}: {}'.format(src, len(qst)))
            print('LENGTHS dst:{}: {}'.format(dst, len(qdt)))
        p = ['{}: duration={}\tat {}  <{} -->  {}>'.format(i, 
            b[0]-t[0],
            t[0], 
            sI, 
            dI 
            ) for i,(b,t) in enumerate(zip(qdt, qst))]
        print('\n'.join(p))
    pass 


def setup_taskgraph_attributes(G, args, cfg, specs):
    for edge in G.edges():
        a,b=edge
#         G.edges[a, b]['NumFlits'] = math.ceil(G.edges[a, b]['volume']/cfg['flitwidth_override'])
        G.edges[a, b]['NumFlits'] = int(G.edges[a, b]['volume'])

    for task in G.nodes():
        G.node[task]['execution_duration']=0
        G.node[task]['energy']=0
        if task in specs['task_kernels']:
            for f in specs['task_kernels'][task]:
                G.node[task]['execution_duration'] += f['duration']
                G.node[task]['energy']    += f['energy']

"""
post nasm updates
"""
def update1_taskgraph_attributes(G, cfg, specs, dist, path):
    # edge attributes
    # comm on edge: start, end times
    for a,b in G.edges():
        ra = G.node[a]['HostRouter']
        rb = G.node[b]['HostRouter']
        G.edges[a, b]['tstart'] = G.node[a]['tstart'] + G.node[a]['execution_duration']
        G.edges[a, b]['tend']   = G.edges[a, b]['tstart'] + G.edges[a, b]['NumFlits'] * dist[ra][rb] * specs['hop_latency']

    # path attributes
    for a,b in G.edges():
        def link_t(a, b):
            return G.edges[a, b]['NumFlits'] * specs['hop_latency']

        ra = G.node[a]['HostRouter']
        rb = G.node[b]['HostRouter']
        G.edges[a, b]['path'] = {}
        currTime = G.edges[a, b]['tstart']
        for link in path[ra][rb]:
            G.edges[a, b]['path'][link] = {'tstart': currTime, 'tend': currTime + link_t(a, b)}
            currTime += link_t(a, b)


def write_tikz_lines(G, fname):
    with open(fname, 'w') as fh:
        fh.write("%Nodes\n")
#         for node in G.nodes():
        for node in G.nodes(): # networkx version >2.0 
            fh.write('\\node[squarenode] ({0}) [ ] {{{0}}};\n'.format(node))
        fh.write("%Lines\n")
        fh.write("%(post-edit positioning as necessary)\n")
        for a,b in G.edges():
            edgeattr = G.edges[a, b]['volume']
            if isinstance(edgeattr, float) and math.ceil(edgeattr) == math.floor(edgeattr):
                edgeattr = int(edgeattr)
            line = '\draw[triangle 45 - triangle 45] ({}) -- ({})  node [edgelabel] {{{}}} '.format(a, b, edgeattr) + ';\n'
            fh.write(line)


def loadjson(filename):
    with open(filename, 'r') as fh:
        return json.load(fh)
def storejson(d, filename):
    with open(filename, 'w') as fh:
        json.dump(d, fh, indent=4)

def run_nasm(args):
    def outpath(filename):
        return os.path.join(args.outdir, filename)
    def dump_mapinfo(task_router_dict):
        # task:router to router:task 
        mapv0rev = {v:k for k,v in mapv0.items()}
        # visualization for mesh, square NoCs
        mapv1 = ["-"]*M
        for router in routers:
            if router in mapv0rev:
                mapv1[router] = mapv0rev[router]
        storejson(mapv0, outpath('map_t2r.json')) # for use as-is by nac
        storejson(mapv0rev, outpath('map_r2t.txt'))
        storejson(mapv1, outpath('map_routeroccupancy.txt'))
        with open(outpath('map.tikzdef'), 'w') as fh:
            ss = ', '.join('"{}"'.format(x) for x in mapv1)
            ss = r'\def\rtmap{{' + ss + '}};\n'
            fh.write(ss)

        
        # console map visualization for mesh
        if psn_util.is_topology_mesh(cfg['nocpath']):
            order = list(chunks(mapv1, int(math.sqrt(M))))
            with open(outpath('map.mesh'), 'w') as fh:
                fh.write(meshprint(order))
                print(meshprint(order))
        
    # prepare output layout
    outdir = args.outdir
    trymkdir(outdir)

    # load application config, specs
    cfg = loadjson( os.path.join(args.graphdir, 'config.json'))
    specs = loadjson( os.path.join(args.graphdir, 'specs.json'))

    graph = read_post_na_graph( os.path.join(args.graphdir, 'graph.txt'), specs, merged=True)
    G_ssplit, task_clusters_ssplit = to_graph_with_send_arcs_made_dummy_tasks(graph)

    if args.use_tracelog:
        graph_all = read_post_na_graph( os.path.join(args.graphdir, 'graph_all.txt'), specs, merged=False)
        update_G_from_tracelog(graph_all, 'tracelog.db', args.startpos, args.endpos)
    if args.endpos:
        sys.exit(1)
    
    # setup for a formulation to run
    if args.formulation1 and args.objective == 'energy' and not args.keeppc:
        cfg['drop_precedence_constraints'] = True
    
    if args.formulation1 and args.objective in ['both', 'makespan']:
        cfg['drop_precedence_constraints'] = False

    
    
    if args.viz:
        write_dot(graph, 'G.dot')
        write_dot(G_ssplit, 'Gs.dot')
        write_tikz_lines(graph, 'G.tikz')
        sys.exit(0)
    
    write_dot(graph, outpath('G.dot'))
    write_tikz_lines(graph, outpath('G.tikz'))

    # temporarily remove cycles
    count = None
    try:
        count = remove_cycles_temporary(graph)
    except Exception:
        pdb.set_trace()
        pass
    if count: 
        write_dot(graph, outpath('G.nocycles.dot'))
            

    # read NoC topology and routing information 
    _,dist,path,M=psn_util.read_topology_and_routing_info(cfg['nocpath'])
    
    # task, and routers
    tasks = [n for n in graph] # passing G ought to be enough TODO
    routers = dist.keys()
#     print(tasks)

    setup_taskgraph_attributes(graph, args, cfg, specs)
    setup_taskgraph_attributes(G_ssplit, args, cfg, specs)
    

    # if asked to showcost of a given map, do that and quit
    if args.showcost:
        def comVol(edge):
            i, j = edge
#             return graph.edges[i, j]['NumFlits'] * cfg['flitwidth_override'] 
            return graph.edges[i, j]['NumFlits']
        def find_map_cost(taskmap):
            hops = dist
            cost_A = 0
            for a, b in graph.edges():
                mh_dist = 0
                ra = taskmap[a]
                rb = taskmap[b]
                cost_A += comVol((a, b))*hops[ra][rb]
#                 for m in routers:
#                     for n in routers:
#                         if taskmap[a] == m and taskmap[b] == n:
#                             mh_dist +=  hops[m][n]
#                 cost_A += comVol((a, b))*mh_dist 
            return cost_A
        tmap = loadjson(args.showcost)
        print('cost = {}'.format(find_map_cost(tmap)))
        sys.exit(0)


    if args.formulation1:
        mapv0 = nasm(tasks,routers,args,specs,cfg,graph,dist,path)
        if 0: # TODO come back to this later
            update1_taskgraph_attributes(graph, cfg, specs, dist, path)
        dump_mapinfo(mapv0)
        nx.write_gexf(graph, outpath('G.gexf'))
    
    elif args.fmesh:
        mapv0 = na_meshILPv1(tasks,routers,args,specs,cfg,graph,dist,path)
        if 0: # TODO come back to this later
            update1_taskgraph_attributes(graph, cfg, specs, dist, path)
        dump_mapinfo(mapv0)
        nx.write_gexf(graph, outpath('G.gexf'))
    
    elif args.f1msgsched_2phase:
        specs['initial_map'] = loadjson(args.f1msgsched_2phase)
        cfg['task_clusters'] = task_clusters_ssplit 
        if args.objective == 'energy':
            print('WARN: energy, wrong choice.')
            args.objective == 'makespan'
        # this.. is just so we don't have to make that constraint conditional
        # while keeping the constraints compatible
        cfg['num_tasks_per_router_bound'] =  max ( len(c) for c in task_clusters_ssplit.values() )  + 1 # + 1 for the host
        mapv0, order_of_sends_in_task = nasm_msgsched(tasks,routers,args,specs,cfg,graph,G_ssplit, dist,path)
    else:
        print('pick formulation to run')
        sys.exit(1)
    print(mapv0)
    
    


#Function to remove overlaps from the given IntervalTree and numVCs
def remove_Overlaps(t,step):
    stop=False
    while not stop:
        minT=sorted(t)[0].begin
        maxT=sorted(t)[-1].end
        stop=True
        time=minT
        slack={}
        removeIntervals=set()
        while time<=maxT:
            s=sorted(t[time])
            if len(s)>1:
                stop=False
                for i in range(1,len(s)):
                    if s[i] not in removeIntervals:
                        removeIntervals.add(s[i])
                    if s[i].data not in slack:
                        slack[s[i].data]=0
                    slack[s[i].data]+=1
            time+=step
        for item in removeIntervals:
            newInterval=Interval(item.begin+slack[item.data],item.end+slack[item.data],item.data)
            t.remove(item)
            t.add(newInterval)
    return t
#Function to adjust timing of all downstream edges and nodes from the curent node
def adjustTiming(TG,path,node,node_over=True,edge_over=True):
    Q=queue.Queue()
    Q.put(node)
    while not Q.empty():
        i=Q.get()
        maxT=0
        for j in TG.predecessors(i):
            if TG.edges[j, i]['tend']>maxT:
                maxT=TG.edges[j, i]['tend']
        if TG.node[i]['tstart']<maxT:
            node_over=False
            TG.node[i]['tstart']=maxT
        endTime=TG.node[i]['tstart']+TG.node[i]['execution_duration']
        for j in TG.successors(i):
            if TG.edges[i, j]['tstart']<endTime:
                edge_over=False
                slack=endTime-TG.edges[i, j]['tstart']
                t1,t2=TG.node[i]['HostRouter'],TG.node[j]['HostRouter']
                for link in path[t1][t2]:
                    TG.edges[i, j]['path'][link]['tstart']+=slack
                    TG.edges[i, j]['path'][link]['tend']+=slack
                if t1!=t2:
                    TG.edges[i, j]['tstart']=min(TG.edges[i, j]['path'][link]['tstart'] for link in path[t1][t2])
                    TG.edges[i, j]['tend']=max(TG.edges[i, j]['path'][link]['tend'] for link in path[t1][t2])
                else:
                    TG.edges[i, j]['tstart']+=slack
                    TG.edges[i, j]['tend']+=slack

                Q.put(j)
    return node_over,edge_over


def examine1(args):
    def outpath(filename):
        return os.path.join(args.outdir, filename)
    def update_G_attrs_1(G, specs, cfg, dist):
        G.graph['FlitWidth']=cfg['flitwidth_override']
        G.graph['Makespan']=max(G.node[node]['tstart']+G.node[node]['execution_duration'] for node in G.nodes())
        G.graph['E_core']=sum(G.node[node]['energy'] for node in G.nodes())
        G.graph['E_comm']=sum(G.edges[a, b]['NumFlits']*G.graph['FlitWidth']*dist[G.node[a]['HostRouter']][G.node[b]['HostRouter']]*specs['energy_cost_per_bit'] for a, b in G.edges())

    cfg = loadjson( os.path.join(args.graphdir, 'config.json'))
    specs = loadjson( os.path.join(args.graphdir, 'specs.json'))
    G = nx.read_gexf(outpath('G.gexf'))
    ### prep ###
    # remove node labels, edge ids
    for n in G.nodes():
        del G.node[n]['label']
    for a,b in G.edges():
        del G.edges[a, b]['id']
    # get back from string
    for a,b in G.edges():
        G.edges[a, b]['path'] = eval(G.edges[a, b]['path'])
    
    
    # read NoC topology and routing information 
    _,dist,path,M=psn_util.read_topology_and_routing_info(cfg['nocpath'])

    #
    update_G_attrs_1(G, specs, cfg, dist)
    G_old = G.copy()
    # check for overlaps
    routers = dist.keys()
    directLinks = [(a,b) for a in routers for b in routers if dist[a][b]==1]
    TIME_STEP=1
    edge_over=False
    node_over=False
    while not (edge_over and node_over):
        edge_over=True
        node_over=True
        changed=False
        routeCount={link:{'count':0,'edgeList':[]} for link in directLinks}
        for edge in G.edges():
            n1,n2=edge[0],edge[1]
            t1,t2=G.node[n1]['HostRouter'],G.node[n2]['HostRouter']
            
            for link in path[t1][t2]:
                routeCount[(link[0],link[1])]['count']+=1
                tempD={}
                tempD['Edge']=(n1,n2)
                tempD['tstart']=G.edges[n1, n2]['path'][link]['tstart']
                tempD['tend']=G.edges[n1, n2]['path'][link]['tend']
                routeCount[(link[0],link[1])]['edgeList'].append(tempD)

        #Check which links have count>1

        for link in routeCount:
            if routeCount[link]['count']>1:
                #Check whether this link has congestion problem or not
            
                #create an IntervalTree and pass to to removeOverlaps fucntion
                t=IntervalTree()
                for edge in routeCount[link]['edgeList']:
                    t[edge['tstart']:edge['tend']]=edge['Edge']
                t=remove_Overlaps(t,TIME_STEP)
            
                #Copy information from IntervalTree to corresponding G edges
                for interval in t:
                    edge=interval.data
                    if G.edges[edge[0], edge[1]]['path'][link]['tstart']!=interval.begin:
                        G.edges[edge[0], edge[1]]['path'][link]['tstart']=interval.begin
                        G.edges[edge[0], edge[1]]['path'][link]['tend']=interval.end
                        changed=True

        #Recalculate Start and end times of all changed edges
        if changed:    
            for edge in G.edges():
                n1,n2=edge[0],edge[1]
                t1,t2=G.node[n1]['HostRouter'],G.node[n2]['HostRouter']
                if t1!=t2:
                    G.edges[n1, n2]['tstart']=min(G.edges[n1, n2]['path'][link]['tstart'] for link in path[t1][t2])
                    G.edges[n1, n2]['tend']=max(G.edges[n1, n2]['path'][link]['tend'] for link in path[t1][t2])
        
        

        #Check whether after adjusting start_times of nodes, any node execution overlaps within a single tile
        tileCount={tile:{'count':0,'nodeList':[]} for tile in routers}
        for node in G.nodes():
            t=G.node[node]['HostRouter']
            tileCount[t]['count']+=1
            tempD={}
            tempD['Node']=node
            tempD['tstart']=G.node[node]['tstart']
            tempD['tend']=G.node[node]['tstart']+G.node[node]['execution_duration']
            tileCount[t]['nodeList'].append(tempD)

        for tile in tileCount:
            if tileCount[tile]['count']>1:
                #Check whether this tile has congestion problem or not
            
                #create an IntervalTree and pass to to removeOverlaps fucntion
                t=IntervalTree()
                for node in tileCount[tile]['nodeList']:
                    t[node['tstart']:node['tend']]=node['Node']
                t=remove_Overlaps(t,1,TIME_STEP)
            
                #Copy information from IntervalTree to corresponding G nodes
                for interval in t:
                    node=interval.data
                    if G.node[node]['tstart']!=interval.begin:
                        G.node[node]['tstart']=interval.begin
        
        #Adjust the start time of all nodes and edges of G depending on the end times of all incoming edges and nodes of G
        totalTime=0
        for node in nx.topological_sort(G):
            maxT=0
            for pred in G.predecessors(node):
                if G.edges[pred, node]['tend']>maxT:
                    maxT=G.edges[pred, node]['tend']
            if G.node[node]['tstart']<maxT:
                G.node[node]['tstart']=maxT
                node_over,edge_over=adjustTiming(G, path,node)

            if G.node[node]['tstart']+G.node[node]['execution_duration']>totalTime:
                totalTime=G.node[node]['tstart']+G.node[node]['execution_duration']
          

    update_G_attrs_1(G, specs, cfg, dist)
    changes={node:G.node[node]['tstart']-G_old.node[node]['tstart'] for node in G.nodes()}
    for node in changes:
        if changes[node]:
            print('\tNode',node,'is shifted by',changes[node],'time units')

    print("NEW", G.graph)
    print("OLD", G_old.graph)
    
    print('Starting to compute slacks')

    #find slack time for each task
    maxINT=1000000
    for node in G.nodes():
        G.node[node]['tslack']=maxINT

    for node in G.nodes():
        for in_node in G.predecessors(node):
            diff=G.node[node]['tstart']-G.edges[in_node, node]['tend']
            if G.node[in_node]['tslack']>diff:
                G.node[in_node]['tslack']=diff

    for node in G.nodes():
        if G.node[node]['tslack']==maxINT:
            G.node[node]['tslack']=G.graph['Makespan']-(G.node[node]['tstart']+G.node[node]['execution_duration'])

    #Now after finding slack for all tasks, look for individual cores
    #A core can be slowed down by an amount = min(slack times of all the tasks mapped onto it)

    Tile_task={i:[] for i in routers}

    for node in G.nodes():
        Tile_task[G.node[node]['HostRouter']].append(node)

    for tile in Tile_task:
        if len(Tile_task[tile])>0:
            m=min(Tile_task[tile],key=lambda x:G.node[x]['tslack'])
            if G.node[m]['tslack']!=0:
                print('Core/Tile',m,'can be slowed down by',G.node[m]['tslack'],'units of time')


    
    
    
    print('Writing updated taskgraph to file')
    nx.write_gexf(G, outpath('G_rcheck.gexf'))   



def run():
    import configargparse
    p = configargparse.ArgParser()
    p.add('-c', '--my-config', required=False, is_config_file=True, help='config file path')
    p.add('-g', '--graphdir', action="store", metavar='GRAPH_DIRECTORY', required=True, help="")
    p.add('-o', '--outreldir', action="store", metavar='OPTI_RESULTS_RELPATH', dest="outdir", default="out_default", required=False)
    p.add('-e', '--mode-examine', action="store_true", help="Examine a generated solution in GRAPH_DIRECTORY/OPTI_RESULTS_RELPATH")
    p.add('-f1', '--formulation1', action="store_true", help="Run formulation 1 (see -f1opts)")
    p.add('--objective', action='store', choices=['makespan','energy','both'], default='energy')
    p.add('-f1opts', choices=['Lobj', 'Lconstr', 'Lboth', 'Qall'], default='Qall', action="store", help="Run formulation 1 with options [L]inearize or [Q]uad defaults")
    p.add('-fmesh', '--fmesh', action="store_true", help="Run ILP mesh formulation")
    p.add('-f1msgsched-2phase', metavar="INITIAL_TASKMAP_FILE", help='message scheduling: the two phase approach assuming a placed design ')
    p.add('-keeppc', action='store_true')
    p.add('--tune-gurobi', action="store_true", help="Tune gurobi parameters before optimizing; store tune/prm files to GRAPH_DIRECTORY/OPTI_RESULTS_RELPATH")
    # miscellaneous bits
    p.add('-viz','--viz', help="Write G.dot/G.tikz in PWD and quit.", action="store_true")
    # 
    p.add('--startpos', action="store", help="[taskname:]stmtname:lineno")
    p.add('--endpos', action="store",   help="[taskname:]stmtname:lineno")
    p.add('--use-tracelog', action="store_true", default=False)
    p.add('-showcost', metavar='TASKMAP_JSON', help="Display the cost(s) of a given taskmap", default=False)

    
    
    args = p.parse_args()
    # make outdir, a relpath to graphdir
    args.outdir = os.path.join(args.graphdir, args.outdir)
 
    if args.mode_examine:
        examine1(args)
    else:
        run_nasm(args)

if __name__ == "__main__":
    run()












