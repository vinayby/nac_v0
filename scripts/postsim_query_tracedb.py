#! /usr/bin/env python
# -*- coding: utf-8 -*-
""" [2018] vbyk
"""
################## vim:fenc=utf-8 tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import os
import pdb

import sqlite3
from collections import namedtuple

def loadjson(filename):
    import json
    try:
        with open(filename, 'r') as fh:
            return json.load(fh)
    except Exception as e:
        raise e

file_taskmap        = 'taskmap.json'
file_lineinfo       = '../ispecs/line_annotations.json'
na_lineinfo         = loadjson(file_lineinfo)
g_taskmap           = loadjson(file_taskmap)
g_taskmap_inv       = {v: k for k, v in g_taskmap.items()}
g_conn              = sqlite3.connect('tracelog.db')
g_dbc               = g_conn.cursor()
stmt_names          = g_dbc.execute('SELECT DISTINCT name FROM natrace').fetchall()
stmt_names          = [n[0] for n in stmt_names]
stmt_name_shorthand = {n[0]:n for n in stmt_names}
        
ArcTrace = namedtuple('ArcTrace', ['duration', 'idealduration', 'start', 'src', 'dst', 'src_id', 'dst_id', 'nHops', 'cVol'])
StmtTrace = namedtuple('StmtTrace', ['type','duration', 'start', 'taskname', 'lno'])
class StmtLineInfo(object):
    def __init__(self, taskname, lno, lvl, name=''):
        self._taskname = taskname
        self._tid = None
        if taskname:
            self._tid = g_taskmap[taskname]
        self._lno = lno
        self._lvl = lvl
        self._name = name
    def __repr__(self):
        return '{}:l{}:d{}_{}'.format(self._taskname, self._lno, self._lvl, self._name)

def look_for_blocks(dbc, only_blocking_sends=True):
    blocked_stmts = []
    # DUPLICATED FROM analyse_arcs ----------_BEGIN
    # read arc annotations from ../taskgraph/graph_all.txt 
    def read_post_na_graph(filename, merged=True):
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
                G.add_edge(src, dst, label=float(val1), volume=float(val1))
            else:
                  src, dst, val1,   src_lno, src_lvl, src_stmtname,     dst_lno, dst_lvl, dst_stmtname = edge.split()
                  src = '{}:{}:{}'.format(src,src_stmtname,src_lno)
                  dst = '{}:{}:{}'.format(dst,dst_stmtname,dst_lno)
                  G.add_edge(src, dst, label=float(val1), volume=float(val1), 
                          slineno=src_lno, dlineno=dst_lno, 
                          slevel=src_lvl, dlevel=dst_lvl,
                          sname=src_stmtname, dname=dst_stmtname)
        return G
    
    taskgraph_dir = '../taskgraph/'
    graph_arc_annotations = os.path.join(taskgraph_dir, 'graph_all.txt')
    fitter_cfg = loadjson(os.path.join(taskgraph_dir, 'config.json'))
    fitter_specs = loadjson(os.path.join(taskgraph_dir, 'specs.json'))
    # read NoC topology and routing information 
    import psn_util
    _,hops,rpath,numRouters=psn_util.read_topology_and_routing_info(fitter_cfg['nocpath'])

    G = read_post_na_graph(graph_arc_annotations, merged=False)
    # END OF DUPLICATION
    
    for k, v in g_taskmap.items():
        q = "SELECT * from natrace WHERE tid='{}' ORDER BY tick".format(v)
        r = g_dbc.execute(q).fetchall()
        if not r:
            continue 
        last_stmt = r[-1]
        if last_stmt[2] == 'top' and last_stmt[-1] != 'halt':
            if only_blocking_sends:
                if last_stmt[-1] == 'send':
                    blocked_stmts.append((k, last_stmt))
            else:
                blocked_stmts.append((k, last_stmt))

    for tname, r in sorted(blocked_stmts, key=lambda x: x[1][0]):
        tick, tid, topbottom, lvl, line, stmtname = r 
        print('at tick = {}: {} in task {} (at {}) line {} blocked'.format(tick, stmtname, tname, tid, line))
        if stmtname == 'send':
            for a, b in G.edges():
                sX = expand_(a)    
                sY = expand_(b)    
                if g_taskmap[tname] == tid and line == sX._lno and lvl == sX._lvl :
                    p = rpath[sX._tid][sY._tid]
                    print("\tARC {} -> {} USES path={}".format(sX, sY, p))

    pass 

def query_template1(stmt, top_nbottom):
    if stmt._tid is not None:
        q="SELECT tick,lvl,tid FROM natrace WHERE name='{}' and lno={} and lvl={} and tid={} and ev_ts='{}' ORDER BY tick".format(stmt._name, stmt._lno, stmt._lvl, stmt._tid, top_nbottom)
    else:
        q="SELECT tick,lvl,tid FROM natrace WHERE name='{}' and lno={} and lvl={} and            ev_ts='{}' ORDER BY tick".format(stmt._name, stmt._lno, stmt._lvl,            top_nbottom)
    r = g_dbc.execute(q).fetchall()
    return r

def time_spent_at_stmt(dbc, stmt, do_stdout=False, brief=False):
    rt = query_template1(stmt, 'top')
    rb = query_template1(stmt, 'bottom')
    p = [(i, b[0]-t[0], t[0], stmt, g_taskmap_inv[b[2]]) for i,(b,t) in enumerate(zip(rb, rt))]
    if do_stdout:
        spl = ['{}: duration={}\t starting at {} in {}({})'.format(*tup) for tup in p]
        print('\n'.join(spl))
        avg_duration = sum([tup[1] for tup in p])
        print('avgDuration = {}\n'.format(avg_duration/len(p)))
    rl = []
    for e in p:
        r = StmtTrace(type=stmt._name, duration=e[1], start=e[2], taskname=stmt._taskname, lno=stmt._lno)
        rl.append(r)

    return rl

def time_spent_between_stmtX_top_stmtY_bottom(dbc, sX, sY, do_stdout=False):
    xt = query_template1(sX, 'top')
    xb = query_template1(sY, 'bottom')
    p_ = [(i, 
        b[0]-t[0],
        t[0], 
        sX, 
        g_taskmap_inv[t[2]],
        sY, 
        g_taskmap_inv[b[2]] 
        ) for i,(b,t) in enumerate(zip(xb, xt))]
    if do_stdout:
        sp = ['{}: duration={}\t starting at {}  <{}({}) -->  {}({})>'.format(*tup) for tup in p_] 
        avg_duration = sum([tup[1] for tup in p_])
        print('\n'.join(sp))
        print('avgDuration = {}\n'.format(avg_duration/len(p_)))
    rl = []
    for e in p_:
        xtid = g_taskmap[e[4]]
        ytid = g_taskmap[e[6]]
#         assert xtid == sX._tid  sX._tid could be None
#         assert ytid == sY._tid
        r = ArcTrace(e[1], None, e[2], sX._taskname, sY._taskname, xtid, ytid, None, None)
        rl.append(r)

    return rl

def expand_(a, verbose=False):
    """ [taskname:]stmt_shorthand:line_no --> StmtLineInfo """
    ll = a.split(':')
    sh, lno = ll[-2:] # last two items
    taskname = None
    if len(sh) != 1:  # reduce to short-hand if necessary
        sh = sh[0]
    name = stmt_name_shorthand[sh]
    if len(ll) == 3:
        taskname = ll[0]
    if lno in na_lineinfo:
        for e in na_lineinfo[lno]: # find stmt that matches name
            if name == e[2]:
                if verbose:
                    print('expanded: ', e)
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
        if verbose:
            print('expanded: ', e)
        return StmtLineInfo(taskname, *e)
    print("line specification incorrect, quitting\n")
    sys.exit(1)
    pass
import networkx as nx
from intervaltree import Interval, IntervalTree
def analyse_congestion(arc_trace_context, rpath):
    itree = IntervalTree()
    arc_associated_conflicting_arcs = {} # arc: [(xarc, linkoverlaps)...]
    # Add arcs to an intervaltree based on arc-duration intervals
    for sstmt, arc, rstmt in arc_trace_context:
        arcpath = rpath[arc.src_id][arc.dst_id]
        # count the last transition to dst node as a (dst, dst) link 
        # to explain the common destination congestion
        arcpath.append((arc.dst_id, arc.dst_id))
        t_s, t_e = arc.start, arc.start+arc.duration
        itree[t_s:t_e] = (set(arcpath), arc)
    
    arc_path_overlaps_that_matter = {} # arc: [(nLinksOverlap, arcX)]
    # With a sorted list of arcs, sorted by the worst to least negative slack
    #   find the arcs that were active during the interval of THIS ARC
    for ss, arc, rs in sorted(arc_trace_context, key=lambda x: x[1].duration-x[1].idealduration, reverse=True):
        slack = -arc.duration + arc.idealduration 
        t_s, t_e = arc.start, arc.start+arc.duration
        # arcs happening during this time, in order
        aset = sorted(itree.search(t_s, t_e))
        asetl = list(aset)
        ARCPATH = set(rpath[arc.src_id][arc.dst_id]) # THIS arcpath # to set() as we'll need set operations next
        
        # ARCHPATH intersections with all except self
        l = [( list(ARCPATH.intersection(ap)), a, (tstart, tend)) for tstart, tend, (ap, a) in asetl if a!=arc] 
        arc_path_overlaps_that_matter[arc] = l
        
        print('\nINTERVAL: {}\t SLACK: {}\t ARC:\t{}'.format((t_s, t_e), slack, arc))
        for linkoverlaps, xarc, xperiod in l:
            if len(linkoverlaps)>0: # at least 1 link overlap
                print('        : {}\t xslack: {}\txARC:\t{}\t\t\tLinks: {}\t{}'.format(
                                                                                           xperiod,
                                                                                           xarc.idealduration-xarc.duration, # slack of the conflict arc
                                                                                           xarc, 
                                                                                           len(linkoverlaps), linkoverlaps))
                if arc not in arc_associated_conflicting_arcs:
                    arc_associated_conflicting_arcs[arc] = []
                arc_associated_conflicting_arcs[arc].append((xarc, linkoverlaps))
#             else:
#                 print('            \t\t\tNo congested links during this interval')
    #itree_incl_path
#     ll = [(ts, te) for ts, te, (arc, xarc, linkoverlaps) in sorted(itree_incl_path.search(83, 776))]
    return arc_associated_conflicting_arcs

            
    pass 

def analyse_arcs(dbc, args):
    # read arc annotations from ../taskgraph/graph_all.txt 
    def read_post_na_graph(filename, merged=True):
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
                G.add_edge(src, dst, label=float(val1), volume=float(val1))
            else:
                  src, dst, val1,   src_lno, src_lvl, src_stmtname,     dst_lno, dst_lvl, dst_stmtname = edge.split()
                  src = '{}:{}:{}'.format(src,src_stmtname,src_lno)
                  dst = '{}:{}:{}'.format(dst,dst_stmtname,dst_lno)
                  G.add_edge(src, dst, label=float(val1), volume=float(val1), 
                          slineno=src_lno, dlineno=dst_lno, 
                          slevel=src_lvl, dlevel=dst_lvl,
                          sname=src_stmtname, dname=dst_stmtname)
        return G
    
    taskgraph_dir = args.arcs
    graph_arc_annotations = os.path.join(taskgraph_dir, 'graph_all.txt')
    fitter_cfg = loadjson(os.path.join(taskgraph_dir, 'config.json'))
    fitter_specs = loadjson(os.path.join(taskgraph_dir, 'specs.json'))
    # read NoC topology and routing information 
    import psn_util
    _,hops,rpath,numRouters=psn_util.read_topology_and_routing_info(fitter_cfg['nocpath'])

    G = read_post_na_graph(graph_arc_annotations, merged=False)
    arcinfo_list = []
    arc_trace_context = []
    for edge in G.edges():
        a, b = edge
        sX = expand_(a)    
        sY = expand_(b)    
        [sendtr] = time_spent_at_stmt(dbc, sX)
        [recvtr] = time_spent_at_stmt(dbc, sY)
        [arcinfo] = time_spent_between_stmtX_top_stmtY_bottom(dbc, sX, sY)
        # 4  + (3 + hops) + vol * (3 cyc / 2 fperpkt) + 4
        numHops_ = hops[arcinfo.src_id][arcinfo.dst_id]
	cycles_per_pkt = fitter_specs['cycles_per_pkt']
        zeroload_tx_time = G.edges[edge]['volume']*cycles_per_pkt + numHops_*fitter_specs['hop_latency'] + 3 + 4 + 4
        arcinfo = arcinfo._replace(idealduration = zeroload_tx_time, nHops=numHops_, cVol=int(G.edges[edge]['volume']))
        arcinfo_list.append(arcinfo)
        arc_trace_context.append( [sendtr, arcinfo, recvtr] )
    # sort, worst neg. slack up
    TNegSlack = 0
    for e in sorted(arc_trace_context, key=lambda x: x[1].duration-x[1].idealduration, reverse=True):
        print('\t\t{}'.format(e[0])) 
        slack = -e[1].duration+e[1].idealduration
        print('RAT-AT:{}\t{}'.format(slack, e[1]))
        TNegSlack  += slack
        if slack > 0:
            print('WARN: slack > 0 on arc {}'.format(e[1]))
        print('\t\t{}'.format(e[2])) 
        print('')
    print('TotalNegSlack = {}'.format(TNegSlack))
    idealarcs = [e for e in arcinfo_list if -e.duration+e.idealduration == 0]
    wellplaced_tasks = {(e.src, e.src_id) for e in idealarcs}.union(
            {(e.src, e.src_id) for e in idealarcs}
            )
    for e in wellplaced_tasks:
        print(e)
    analyse_congestion(arc_trace_context, rpath)



def run():
    from argparse import ArgumentParser 
    p = ArgumentParser()
    p.add_argument("-blocks", nargs='?', help="List of incomplete send statements. (pass `all' for all blocks)", const="sends")
    p.add_argument("-t", nargs='+', metavar="StatementLocation", help="""
                    StatementLocation is specified as [taskname:]first_letter_of_stmt:lno. 
                    Reports the time spent at statement (first argument) or the time spent between two statements (top of 1st and bottom of 2nd).
                    If the (optional) taskname is not specified, reports for all task instances. 
                    """)
    p.add_argument("-arcs", help="Analysis of arcs. Pass path to taskgraph/ folder with graph_all.txt/specs.json")
    p.add_argument("-lastbarrier", help="Print the (time, taskname) of the last completing barrier statement", action="store_true")
    args = p.parse_args()
    if args.arcs:
        analyse_arcs(g_dbc, args)
    if args.lastbarrier:
        q = "SELECT tick, tid, lno FROM natrace WHERE name='barrier' AND ev_ts='bottom' ORDER BY tick;"
        r = g_dbc.execute(q).fetchall()
        tick, tid, lno = r[0]
        print('{}:{}'.format(tick, g_taskmap_inv[tid]))

    if args.blocks:
        only_blocking_sends = args.blocks != 'all'
        look_for_blocks(g_dbc, only_blocking_sends)
    if args.t:
        if len(args.t) == 1:
            sX = expand_(args.t[0], True)    
            time_spent_at_stmt(g_dbc, sX, True)
        elif len(args.t) == 2:
            sX = expand_(args.t[0], True)    
            sY = expand_(args.t[1], True)    
            time_spent_between_stmtX_top_stmtY_bottom(g_dbc, sX, sY, do_stdout=True)

        else:
            print('TODO')

                                  
                                  
if __name__ == "__main__":
    run()                                  
