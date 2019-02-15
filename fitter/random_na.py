#! /usr/bin/env python3
# -*- coding: utf-8 -*-
""" [2018] vbyk
"""
################## vim:fenc=utf-8 tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import os
import pdb
import subprocess

PACKAGE_PARENT = '..'
SCRIPT_DIR = os.path.dirname(os.path.realpath(os.path.join(os.getcwd(), os.path.expanduser(__file__))))
sys.path.append(os.path.normpath(os.path.join(SCRIPT_DIR, PACKAGE_PARENT)))

"""
Paths to resources files relative to toolroot_main, even when used with pyinstaller
"""
def resourcePath(relativePath):
    try:
        basePath = sys._MEIPASS
    except Exception:
        basePath = os.path.abspath(os.path.join(SCRIPT_DIR, PACKAGE_PARENT))

    return os.path.join(basePath, relativePath)

if getattr(sys, 'frozen', False):
    toolroot = resourcePath('.')

#import networkx as nx
from collections import OrderedDict 
def loadjson(filename):
    import json
    with open(filename, 'r') as fh:
        return json.load(fh, object_pairs_hook=OrderedDict)


def run_cmd(scmd, display_stdout=False):
    process = subprocess.Popen(scmd, shell=True, stdout=subprocess.PIPE)
    sout = process.communicate()[0]
    if display_stdout:
        print(sout.decode('utf8'))
    return sout.decode('utf8')

def run_daggen(options):
#     run_cmd(resourcePath('fitter/randomdags/daggen/daggen -h'), True)
    scmd = SCRIPT_DIR + "/randomdags/daggen/daggen -n {0} --mindata {1} --maxdata {2} --fat {3} --ccr {4} --rseed {5} --jump {6} --density {7} --regular {8}".format(
                options.n,    
                options.dminmax[0],
                options.dminmax[1],
                options.fat,
                options.ccr,
                options.rseed,
                options.jump,
                options.density,
                options.regularity
            )
    ss = run_cmd(scmd)
    print(scmd)
    return ss

class Task(object):
    def __init__(self, id, cost, children):
        self._id = id
        self._cost = cost 
        self._children = children 
        self._recvs = []
        self._sends = []
        self._parents = []
        self.is_end_node = False
    def renames(self, remap_dict):
        f = remap_dict 
        self._id = f[self._id]
        self._recvs = [[f[id], cost] for id, cost in self._recvs]
        self._sends = [[f[id], cost] for id, cost in self._sends]
    def addsend(self, dst, cost):
        self._sends.append([dst, cost])
    def addrecv(self, src, cost):
        self._recvs.append([src, cost])
    @property
    def not_disconnected(self):
        if self._sends or self._recvs: # at least 1 s/r 
            return True
        return False


        
def load_dag(daggen_out):
    comp = []
    send = []
    root = []
    end  = []
    tasks = {}
    ll = daggen_out.splitlines()
    _, rseed_value = ll[2].split()
    _, numNodes = ll[3].split()
    ll = ll[4:]
    for l in ll:
        NODE, id, children, nodetype, nodecost, paralleloverhead = l.split()
        if nodetype == 'COMPUTATION':
            comp.append(id)
            tasks[id] = Task(id, nodecost, children.split(','))
        if nodetype == 'TRANSFER':
            send.append(id)
            dst_id = children 
            tasks[id] = Task(id, nodecost, [dst_id])
        if nodetype == 'ROOT':
            root.append(id)
            tasks[id] = Task(id, 0, children.split(','))
        if nodetype == 'END':
            end.append(id)
            tasks[id] = Task(id, 0, [])
    
    for id in comp:
        for txt_id in tasks[id]._children: # comp's children are transfer tasks (with 1-pred, 1-succ); OR the END task
            tasks[txt_id]._parents.append(id)
            if txt_id in end:
                continue
            assert len(tasks[txt_id]._children) == 1
            succ_id = tasks[txt_id]._children[0]
            tasks[id].addsend(succ_id, tasks[txt_id]._cost) 
            tasks[succ_id].addrecv(id, tasks[txt_id]._cost)



    
    for id in end:
        for parent_id in tasks[id]._parents:
            tasks[parent_id].is_end_node = True
    if 0:
        # eliminate tasks (only the comp list) that are disconnected
        rtasks = {id: tasks[id] for id in comp if tasks[id].not_disconnected} 
        return rtasks, rseed_value 
    else: 
        # re-assign task ids starting from 1
        rtasks = [(id, tasks[id]) for id in comp if tasks[id].not_disconnected] # a dict looses order
        idmap = {}
        for i, (id, _) in enumerate(rtasks):
            idmap[id] = i+1
        for id, task in rtasks:
            task.renames(idmap)
        rtasks_ = {t._id : t for _, t in rtasks}
        return rtasks_, rseed_value

def generate_na(tasks, rseed_value, args):
    def id2name(id):
        return "t{}".format(id)
    # also, gather kernel durations = {taskname: kernelduration}
    task_kernel_durations = {}
    # end-node-list
    end_taskname_list = [id2name(id) for id, t in tasks.items() if t.is_end_node]
    # print out .na
    sshead = """
    struct X {
        uint32_t e;
    };
    """
    ssl = [sshead]
    for id, t in tasks.items():
       ssl.append('{} (){{'.format(id2name(id)))
       decls=[]
       recvs=[]
       sends=[]
       
       for src, cost in t._recvs:
           decls.append("\t__bram__ struct X i{}[{}];".format(src, cost))
           recvs.append("\trecv i{1},0,{0} from t{1};".format(cost, src))
       
       
       for dst, cost in t._sends:
           decls.append("\t__bram__ struct X o{}[{}];".format(dst, cost))
           sends.append("\tsend o{1},0,{0} to t{1};".format(cost, dst))
       
       kernel = ["\tdelay {};\n".format(t._cost)]
       task_kernel_durations['t{}'.format(id)] = int(t._cost)
       
       
       ssl += decls + ['parallel {'] + recvs + ['}']+  kernel + sends
       
       if t.is_end_node:
           ssl.append('\tbarrier {};'.format(','.join(end_taskname_list)))
           ssl.append("// FINISH\nhalt 0;")
       else:
           if not sends:
               ssl.append("\thalt;")
           if not recvs: # also halt; we don't want the implied loop to kick-in and starting over again
               ssl.append("\thalt;")
           
       
       ssl.append('}')
    ssl.append('//RSEED {}\n//{}'.format(rseed_value, args))
    return '\n'.join(ssl), task_kernel_durations


def generate_cfg(options, nocs_json, noc_choices):
    # cfg file
    scfg = """
noc = {0}
outdir = 1_out
simulator = iverilog
kernel-specs-file = k.specs
no-task-info
event-trace
    """
    [noc] = [b for i, b in noc_choices if i == options.noc]
    noctype = noc[0]
    noc = os.path.join(nocs_json[noctype+'_basedir'], noc[-1])
    return scfg.format(noc)

def write_string_to(ss, outdir, outfile):
    import tempfile
    import shutil
    (dest, name) =  tempfile.mkstemp()
    os.write(dest, bytes(ss, 'UTF-8'))
    os.close(dest)
    shutil.move(name, os.path.join(outdir, outfile))

path = []
g_noc_list_ = []
def get_nocbag_json():
    nocs_json = loadjson(SCRIPT_DIR + '/../nocbag.json')
#     nocs_json = loadjson(resourcePath('/../nocbag.json'))
    def walk(d):
        global path
        global g_noc_list_
        for k,v in d.items():
            if isinstance(v, str) or isinstance(v, int) or isinstance(v, float):
                path.append(k)
                g_noc_list_.append(path + [v])
                path.pop()
            elif v is None:
                path.append(k)
                ## do something special
                path.pop()
            elif isinstance(v, dict):
                path.append(k)
                walk(v)
                path.pop()
            else:
                print("###Type {} not recognized: {}.{}={}".format(type(v), ".".join(path),k, v))
    walk(nocs_json['noc_type'])
    noc_choices = [l for l in g_noc_list_]
    noc_choices = [(i, e) for i,e in enumerate(noc_choices)]
    return nocs_json, noc_choices

def generate_Makefile():
    with open(SCRIPT_DIR + '/data/random_na.Makefile', 'r') as fh:
        return fh.read()

def run():
    import argparse
    nocs_json, noc_choices = get_nocbag_json()
    print('\n'.join(['{}\t{}'.format(e[0], e[1]) for e in noc_choices]))
    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,
            description="Generates a random dag (using github:frs69wq/daggen), cleans it up, and emits an na specification folder. ")
    p.add_argument("-n", help="Number of tasks", type=int, required=True)
    p.add_argument("-noc", choices=range(len(noc_choices)), type=int, required=True)
    p.add_argument("-obdir", "--outbasedir", help="Output directory base directory, full path", default='.')
    # daggen's options
    p.add_argument("-ccr", choices=["N_N", "N2_N"], help="computation/communication type",  default="N_N")
    p.add_argument("-fat", help="DAG width [0, 1] ", type=float, default=0.5)
    p.add_argument("-density", help="[0, 1] min dependencies to full", type=float, default=0.5)
    p.add_argument("-regularity", help="[0, 1] tasks per level", type=float, default=0.9)
    p.add_argument("-jump", help="direct arcs jumping across levels", type=int, default=1)
    p.add_argument("-rseed", help="Use the specified seed instead of the default (getpid, time)", type=int)
    p.add_argument("-dminmax", nargs=2, type=int, default=[30, 50], help="Datasize (N) min, max")
    p.add_argument("-runnac", action='store_true', default=False, help=argparse.SUPPRESS)
    args = p.parse_args()
    
    basename_dir = 'out_rnd_n{}_f{}_r{}_d{}_j{}_ccr{}_noc{}'.format(args.n, args.fat, args.regularity, args.density, args.jump, args.ccr, args.noc)
    outdirpath = os.path.join(args.outbasedir, basename_dir)

    ccrMap = {'N_N': 1, 'N2_N': 2}
    args.ccr = ccrMap[args.ccr]

    dag = run_daggen(args)
    tasks, rseed_value = load_dag(dag)
    os.makedirs(outdirpath, exist_ok=True)
    na_gen, task_kernel_durations = generate_na(tasks, rseed_value, args)
    write_string_to(na_gen, outdirpath, 'rnd.na')
    write_string_to(generate_cfg(args, nocs_json, noc_choices), outdirpath, 'cfg')
    write_string_to(generate_Makefile(), outdirpath, 'Makefile')
    import json
    write_string_to(json.dumps(task_kernel_durations), outdirpath, 'k.specs')
    if args.runnac: 
        os.chdir(outdirpath)
        run_cmd("nac -c cfg -tg rnd.na", True)
        run_cmd("nac -c cfg rnd.na", True)
        run_cmd("nafitter -g 1_out/taskgraph/ -viz")

if __name__ == "__main__":
    run()
