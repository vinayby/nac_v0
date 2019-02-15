#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 2017 vby
############################ vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""
./prog 3x3 
"""
import os,sys,pdb
import json
tasknames = []
indir = sys.argv[1]
if len(sys.argv) >= 2:
    NOC = sys.argv[2].split('x')
    NOC = map(int, NOC)
    NOC = (NOC[0]*NOC[1], NOC[0], NOC[1])
else:
    NOC = (16, 4, 4)
with open(os.path.join(indir, "graph.txt")) as g:
    rl = g.readlines()
    tasknames = rl[2].split()

"""
------------------------ specs.json ---------------------------------------
"""
from collections import namedtuple
KernelInfo = namedtuple("KernelInfo", ["name","energy", "duration"])
def get_task_kernel_list(task):
    f1 = KernelInfo(name="f1", energy=2, duration=2)
    return [f1._asdict()]
dict = {}
dict["energy_cost_per_bit"] = 0.05
dict["initial_map"] = {}
dict["hop_latency"] = 1
dict['task_kernels'] = {task:get_task_kernel_list(task) for task in tasknames}
dict['cycles_per_pkt'] = 1.5

with open(os.path.join(indir, "specs.json"), "w") as oh:
    json.dump(dict, oh, indent=4)

"""
------------------------ config.json ---------------------------------------
"""
cfg = {}
cfg['nocpath'] = '/home/vinay/git.si/nocx/CONNECT_noc_bag/build.t_mesh__n_{0}__r_{1}_c_{2}__v_2__d_4__w_64_peek_vlinks/'.format(*NOC)
cfg['flitwidth_override'] = 1
cfg['drop_precedence_constraints'] = False
cfg['num_tasks_per_router_bound'] = 1
cfg['objective'] = 'both'
cfg['gurobi_timelimit'] = 300

with open(os.path.join(indir, "config.json"), "w") as oh:
    json.dump(cfg, oh, indent=4)
