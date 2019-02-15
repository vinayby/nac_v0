#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 2017 vby
############################ vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

#---------------------------------------------------------------------------------------------------

import sys
import os, errno
import math
import collections
import subprocess
import json
import random
import pdb
from main.network.psn import PSN
from main.na_utils import *
from .tmodel import tmodel
from .nacommon import *

def loadjson(filename):
    import json
    with open(filename, 'r') as fh:
        return json.load(fh)


#---------------------------------------------------------------------------------------------------

from collections import namedtuple
Edge = namedtuple("Edge", ["src", "dst", "fpp", "nop"])
Annotation = namedtuple("annotation", ["name", "lineno", "level"])
Stmt = namedtuple("Stmt", ["taskname", "annotation"])
class EdgeM(object):
    def __init__(self, src, dst, fpp, nop):
        self.src = src
        self.dst = dst
        self.fpp = fpp
        self.nop = nop
    def __repr__(self):
        return '{} {} {} {}'.format(self.src, self.dst, self.nop, self.fpp)
class amodel(object):
    def __init__(self, nafile, nadefsfile, toolroot, types, hwkdecls, tasks, taskgroups, tinstances_unexpanded, tdefs_original, sysargs):
        self.args = sysargs
        self.toolroot = toolroot
        self.nafile_path = None
        self.nafile_postcpp = nafile
        self.namacros_file = nadefsfile
        self.types = types
        self.hwkdecls = hwkdecls
        self.tasks = tasks 
        self.taskgroups = taskgroups
        self.tinstances_unexpanded = tinstances_unexpanded
        self.tdefs_original = tdefs_original
        
        self.tmodels = []
        self.type_table = collections.OrderedDict()
        self.typetags = collections.OrderedDict()
        self.interfpga_links = []
        
        self.psn = PSN(sysargs)
        
        self.global_task_map = collections.OrderedDict()
        self.task_partition_map = collections.OrderedDict()
        self.original_taskmap_json = collections.OrderedDict()
        self.hls_bviwrappers_outdir = None

        """ 
        some default internal options
        """
        # use explicit fifo buffering for flit-i/o between host and the network
        self.use_buffering_tofrom_host = False
        if self.args.buffered_sr_ports:
            self.use_buffering_tofrom_host = True 
        self.buffer_sizing_specs = collections.OrderedDict()

    """
     Generate a task graph for use with the taskgraph
     version0: basic 
        - nodes are tasks
        - for edges 
            foreach task, collect tuples ('send', destination, flits_per_packet, number_of_packets)
     version1:
        - nodes are tasks
        - for edges, consider 
            
    """
            
    def get_task_communication_graph_skeleton(self):
        gl = []
        for tm in self.tmodels:
            dl = tm.get_unique_message_destinations()
            for d in dl:
                gl.append(EdgeM(src=tm.taskname, dst=d, fpp=0, nop=0))
        return gl



    def taskgraph_gen(self):
        taskgraph_outdir = os.path.join(self.outdir, "taskgraph")
        """
        ------------ Generate graph.txt ---------------------------------------
        """
        
        G = []
        allarcs = self.get_all_communication_arcs()
        
#         for tm in self.tmodels:
#             if tm.is_marked_off_chip:
#                 # TODO handle later in a meaningful way
#                 continue
#             info1 = tm.get_send_class_statement_info1()
#             for send_class, _, syminfo, destinations_,nodeobj in info1:
#                 destinations = list(map(tm.resolve_address, destinations_))
#                 """
#                 TODO: after TLV send
#                 """
#                 if send_class == 'send':
#                     for dst in destinations:
#                         # each struct is a packet, and entire array is sent by default
#                         # flits per packet
#                         fpp = self.get_flits_in_type(syminfo.typename)
#                         # number of packets
#                         nop = syminfo.arraysize
#                         if not nodeobj.fullrange():
#                             nop = nodeobj.length - nodeobj.offset;
#                         e = Edge(src=tm.taskname, dst=dst, fpp=fpp, nop=nop)
#                         G.append(e)
#                 elif send_class == 'scatter':
#                     for dst in destinations:
#                         # each struct is a packet
#                         # flits per packet
#                         fpp = self.get_flits_in_type(syminfo.typename)      
#                         # array is sliced into len(destinations) and sent
#                         # number of packets
#                         nop = syminfo.arraysize/len(destinations)
#                         if not nodeobj.fullrange():
#                             nop = (nodeobj.length - nodeobj.offset)/len(destinations);
#                         e = Edge(src=tm.taskname, dst=dst, fpp=fpp, nop=nop)
#                         G.append(e)
#                 elif send_class == 'broadcast':
#                     pass
#                 else:
#                     raise CompilationError("Not implemented yet")
#         def to_graph_txt(G):
#             lines = []
#             lines.append(len(self.tmodels))
#             lines.append(len(G))
#             lines.append(' '.join([x.taskname for x in self.tmodels]))
#             for e in G:
#                 comm_vol_in_flits = e.fpp * e.nop
#                 lines.append('{} {} {} {} {}'.format(e.src, e.dst, comm_vol_in_flits, e.lineno, e.level))
#             return lines
        def merge_allarcs_into_tasklevel_arcs(all_arcs, skel_arcs):
            for skarc in  skel_arcs:
                for a in all_arcs:
                    if (a.src.taskname, a.dst.taskname) == (skarc.src, skarc.dst):
                        skarc.fpp = a.fpp 
                        skarc.nop += a.nop
            return skel_arcs
                        

        def to_graph_txt(G, merged=False):
            lines = []
            lines.append(len(self.tmodels))
            lines.append(len(G))
            lines.append(' '.join([x.taskname for x in self.tmodels]))
            if not merged:
                for e in G:
                    comm_vol_in_flits = e.fpp * e.nop
                    lines.append('{} {} {}\t{} {} {}\t{} {} {}'.format(e.src.taskname, e.dst.taskname, 
                                                        comm_vol_in_flits, 
                                                        e.src.annotation.lineno, e.src.annotation.level, e.src.annotation.name,
                                                        e.dst.annotation.lineno, e.dst.annotation.level, e.dst.annotation.name
                                                        ))
                with open (os.path.join(taskgraph_outdir, 'graph_all.txt'), 'w') as fh:
                    fh.write('\n'.join([str(x) for x in lines]))
            else:
                for e in G:
                    comm_vol_in_flits = e.fpp * e.nop
                    lines.append('{} {} {}'.format(e.src, e.dst, comm_vol_in_flits))
                with open (os.path.join(taskgraph_outdir, 'graph.txt'), 'w') as fh:
                    fh.write('\n'.join([str(x) for x in lines]))

            return lines
        G = merge_allarcs_into_tasklevel_arcs(allarcs, self.get_task_communication_graph_skeleton())
        trymkdir(taskgraph_outdir)
        ll = to_graph_txt(G, merged=True)
        llnew = to_graph_txt(allarcs, merged=False)

        """
        ------------ Generate config.json ---------------------------------------
        """
        cfg = {}
        cfg['nocpath'] = self.psn.dir
        cfg['flitwidth_override'] = self.flit_width
        cfg['drop_precedence_constraints'] = False
        cfg['num_tasks_per_router_bound'] = 1
        cfg['objective'] = 'both'
        cfg['gurobi_timelimit'] = 60*10
        if self.psn.is_connect():
            cfg['noctype'] = 'connect'
        elif self.psn.is_fnoc():
            cfg['noctype'] = 'fnoc'
        else:
            pass

        with open(os.path.join(taskgraph_outdir, "config.json"), "w") as oh:
            json.dump(cfg, oh, indent=4)
            
        """
        ------------ Generate specs.json ---------------------------------------
        """
        from collections import namedtuple
        tasknames = [x.taskname for x in self.tmodels]
        KernelInfo = namedtuple("KernelInfo", ["name","energy", "duration"])
        kspecs = {}
        if self.args.kernel_specs_file:
            kspecs = loadjson(self.args.kernel_specs_file)
        def get_task_kernel_list(task):
            if kspecs:
                f1 = KernelInfo(name="f1", energy=2, duration=kspecs[task])
            else:
                f1 = KernelInfo(name="f1", energy=2, duration=2)
            return [f1._asdict()]
        dict = {}
        dict["energy_cost_per_bit"] = 0.05
        dict["initial_map"] = {}
        dict["hop_latency"] = 1
        dict["cycles_per_pkt"] = 3.0/2
        if self.psn.is_fnoc():
            dict['hop_latency'] = 3
            dict['cycles_per_pkt'] = 8.0/2

        dict['task_kernels'] = {task:get_task_kernel_list(task) for task in tasknames}

        with open(os.path.join(taskgraph_outdir, "specs.json"), "w") as oh:
            json.dump(dict, oh, indent=4)

    @property
    def enabled_lateral_data_io(self):
        return self.args.enable_lateral_bulk_io
    
    def has_scs_type(self, SCSNAME):
        for tm in self.tmodels:
            for k, v in tm.symbol_table.items():
                if v.storage_class == SCSNAME:
                    return True
        return False


    def get_vhls_portname(self, typename, instancename):
        # self.type_table[typename].xxx
        if len(self.type_table[typename].member_info_tuples)==1  and (self.type_table[typename].basictypes[0]):
            if (self.type_table[typename].basictypes[0][:3] != 'ap_'):
                return instancename + '_' + self.type_table[typename].member_info_tuples[0][0]
        if len(self.type_table[typename].member_info_tuples) == 1:
            mname = self.type_table[typename].member_info_tuples[0][0]
            # _V when member_info_tuples[0][1] >= 32, but let's see
            if mname[-1] == '_':
                return instancename + '_' + self.type_table[typename].member_info_tuples[0][0] + 'V'
            else:
                return instancename + '_' + self.type_table[typename].member_info_tuples[0][0] + '_V'
        return instancename
           
    @property
    def taskmap_json_file(self):
        return self.args.taskmap_json_file

    def all_instances_of_type(self, tmodel):
        return [tm1 for tm1 in self.tmodels if tm1.taskdefname == tmodel.taskdefname]
           
    def taskmap(self, taskname):
        #return self.global_task_map[taskname]
        if taskname in self.global_task_map:
            return self.global_task_map[taskname]
        else:
            # TODO neater
            if taskname == '@return':
                return 'saved_source_address'
            else:
                return taskname
    
    def get_lone_scemi_port_id(self): # tmpfix
        l = self.get_tasks_marked_for_exposing_flit_SR_ports()
        if len(l) == 1:
            return l[0][0]
        else:
            return 2
    def has_nonhls_kernels(self):
        for d in self.hwkdecls:
            if not (d.tq == '__vivadohls__'): 
                return True
        return False

    def trace_state_entry_exit(self):
        if self.args.simverbosity == 'state-entry-exit':
            return True
        return False

    """
        assuming ./mainout/{src,sim,...}
        gen ./mainout/bviwrappers/ if na has hlspes, or well, regardless
        gen ./${bsvkernels} 
    """
    def make_wrapper_dirs(self):
        mainout = self.outdir
        hlsbvidir = os.path.join(mainout, "bviwrappers")
        self.hls_bviwrappers_outdir = hlsbvidir
        trymkdir(hlsbvidir)
        
        
        mainout_par = os.path.join(mainout, os.pardir) 

        bsvkernels="bsvwrappers"
        bsvkernels = os.path.join(mainout_par, bsvkernels)
        if self.args.kernelwrapper_outdir:
            bsvkernels = self.args.kernelwrapper_outdir
        self.pelib_dir = bsvkernels
        if self.has_nonhls_kernels():
            trymkdir(bsvkernels)
            
        if self.args.vhlswrap_outdir:
            #self.vhlswrappergen_dir = os.path.join(os.path.dirname(self.nafile_path), self.args.vhlswrap_outdir)
            self.vhlswrappergen_dir = self.args.vhlswrap_outdir
#         if not os.path.exists(self.pelib_dir):
#             raise ValueError(self.pelib_dir,
#                     """does not exist, please create explicitly or specify a
#                                              directory with a switch
#                                                          """)
        # VHLS directory
        if self.args.vhlswrap_outdir:
            trymkdir(self.args.vhlswrap_outdir)
    
    @property
    def hls_source_directory_abspath(self):
        pass
    @property
    def out_scriptdir(self):
        return os.path.join(self.outdir, 'tcl')
    
    @property
    def out_simdir(self):
        return os.path.join(self.outdir, 'sim')

    @property
    def out_swmodeldir(self):
        return os.path.join(self.outdir, 'mpimodel')
    
    def prepare_outdir_layout(self):
        # SETUP OUTDIR LAYOUT
        trymkdir(os.path.join(self.outdir, 'ispecs'))
        trymkdir(os.path.join(self.outdir, 'src'))
        trymkdir(os.path.join(self.outdir, 'tb'))
        trymkdir(self.out_simdir)
        trymkdir(os.path.join(self.outdir, 'data'))
        trymkdir(os.path.join(self.outdir, 'libs'))
        trymkdir(os.path.join(self.outdir, 'fpga'))
        trymkdir(os.path.join(self.outdir, 'libna'))
        trymkdir(os.path.join(self.outdir, 'scemi'))
        trymkdir(self.out_swmodeldir)
        if self.args.scemi:
            trymkdir(os.path.join(self.outdir, 'tbscemi'))
        trymkdir(self.out_scriptdir)
        
        if self.psn.is_connect():
            force_symlink(self.psn.dir, os.path.join(self.outdir, 'connect'))
        if self.psn.is_fnoc():
            force_symlink(self.psn.dir, os.path.join(self.outdir, 'forthnoc'))
        
        #force_symlink(os.path.join(self.toolroot, 'libs'), os.path.join(self.outdir, 'libs'))  
        force_symlink(os.path.join(self.toolroot, 'libs/bsv'), os.path.join(self.outdir, 'libs/bsv'))  
        if self.has_scs_type('__ram__') or self.has_scs_type('__mbus__'):
          force_symlink(os.path.join(self.toolroot, 'libs/bsv_reserve'), os.path.join(self.outdir, 'libs/bsv_reserve'))  
                
        force_symlink(os.path.join(self.toolroot, 'libs/verilog'), os.path.join(self.outdir, 'libs/verilog'))  
        force_symlink(os.path.join(self.toolroot, 'libs/xdc'), os.path.join(self.outdir, 'libs/xdc'))  
        #force_symlink(os.path.join(self.toolroot, 'libs/libna'), os.path.join(self.outdir, 'libs/libna'))  
        force_symlink(os.path.join(self.toolroot, 'libs/vhls_include'), os.path.join(self.outdir, 'libs/vhls_include'))  
        
        self.make_wrapper_dirs()

        # Write taskmap json file
        with open(os.path.join(self.out_simdir, 'taskmap.json'), 'w') as fo:
            json.dump(self.global_task_map, fp=fo, indent=4)


        
        # Dump the mfpga_taskmap.json too
        if self.task_partition_map:
            with open(os.path.join(self.out_simdir, 'original_taskmap.json'), 'w') as fo:
                json.dump(self.original_taskmap_json, fp=fo, indent=4)
            with open(os.path.join(self.out_simdir, 'mfpga_taskmap.json'), 'w') as fo:
                json.dump(self.task_partition_map, fp=fo, indent=4)

        #readback = json.load(open('OUT_CGEN/src/taskmap.json'))
        with open(os.path.join(self.out_simdir, 'typetags.json'), 'w') as fo:
            json.dump(self.typetags, fp=fo, indent=4)



    def setup(self):
        self.nafile_path = self.args.nafile
        trymkdir(self.outdir)
        
        
        # Types 
        #
        self.type_table = collections.OrderedDict()
        for t in self.types:
            self.type_table[t.struct_name] = t
        # Typetags
        self.typetags = collections.OrderedDict()
        for i, t in enumerate(self.type_table.keys()):
            self.typetags[t] = i



        # Hwkernels
        #

        # Tasks
        #
        
        self.tmodels = [tmodel(t) for t in self.tasks]
        for tm in self.tmodels:
            tm.setup()
            tm._gam = self

        if self.taskmap_json_file and os.path.exists(self.taskmap_json_file):
            self.global_task_map, self.task_partition_map = self.parse_taskmap_json(self.taskmap_json_file) 
        
        # Add the interfpga link tasks to tmodels
        if self.has_tasks_marked_for_xfpga: 
            link_tasks = self.get_interfpga_link_tasks()
            link_tmodels = [tmodel((None, t)) for t in link_tasks]
            for tm in link_tmodels:
                tm.setup()
                tm._gam = self
            self.tmodels.extend(link_tmodels)

        
        # task groups using a task instance array name as proxy for all instances, we expand
        def find_name_in_tmodels(name):
            if name in [x.taskname for x in self.tmodels]:
                return True
        def find_if_a_taskinstance_array_name(name):
            tms_with_array_decl = [t for t in self.tmodels if t.instanceparams and t.instanceparams.num_task_instances]
            # we have instance tasks that have been defined as arrays 
            # we check if name matches any of these tasknames MINUS the _%d suffix  
            for t in tms_with_array_decl:
                abc = t.taskname 
                if abc[:abc.rfind('_')] == name:
                    # found, so all the array instances should be accounted for, and sent
                    account_for = t.instanceparams.num_task_instances
                    for t in tms_with_array_decl:
                        abc = t.taskname
                        abc = abc[:abc.rfind('_')]
                        if abc == name:
                            account_for=account_for - 1
                    if account_for == 0:
                        return True, t.instanceparams.num_task_instances



        for k, v in self.taskgroups.items():
            for name in v.tasknamelist:
                if not find_name_in_tmodels(name):
                    found, count = find_if_a_taskinstance_array_name(name)
                    if found:
                        v.tasknamelist.remove(name)
                        v.tasknamelist.extend(["{}_{}".format(name, idx) for idx in range(count)])

                    

        self.set_a_task_map()


        # TODO temporary arrangement 
        # 1. broadcast: assign address_list; to be done after task map
        # 2. recv from @any or @customgroup_name
        for tm in self.tmodels:
            tm.setup_broadcast_stmts()
            tm.setup_recv_taskgroup_stmts()
            tm.setup_send_taskgroup_stmts()
            tm.setup_scatter_taskgroup_stmts()
            tm.setup_gather_taskgroup_stmts()
            tm.setup_barrier_group_resolution()
            tm.setup_pragma_recvs_sends_declarations()

    def get_interfpga_link_tasks(self):
        ifpga_tdl = []
        from main.nac import task_definition 
        for link in self.original_taskmap_json['interfpga_links']:
            (fromfpga, fromnode), (tofpga, tonode) = link.items()
            qualifiers = ['xfpga']
            fromlink_tname = '{}_{}'.format(fromfpga, fromnode)
            tolink_tname = '{}_{}'.format(tofpga, tonode)
            td = task_definition( (None, fromlink_tname, qualifiers) )
            ifpga_tdl.append(td)
            td = task_definition( (None, tolink_tname, qualifiers) )
            ifpga_tdl.append(td)
        return ifpga_tdl
    
    @property
    def number_user_send_ports(self):
        return int(self.psn.params['NUM_USER_SEND_PORTS'])
    @property
    def flit_width(self):
        return int(self.psn.params['FLIT_DATA_WIDTH'])

    @property
    def unused_flit_header_bitcount(self):
        if self.psn.is_fnoc():
            # For FNOC we reserve self.number_user_send_ports for use with broadcast/multicast feature
            return self.flit_width - self.number_user_send_ports - self.get_network_address_width() - self.get_typetags_count_width() - 2 # 2 bits for bcast or multicast indicator 
        elif self.psn.is_connect():
            return self.flit_width - self.get_network_address_width() - self.get_typetags_count_width() 
    
    def sanitychecks(self):
        # CHECK: whether flit width is enough to accomodate the `header flit'
        assert self.unused_flit_header_bitcount >= 0, "FLIT_WIDTH unsufficient to hold the header flit, should at least be {}".format(-self.unused_flit_header_bitcount+self.flit_width)  

        pass
    
    def hwkernelname2modname(self, k):
        return k[0].upper()+k[1:]
    def hwmodname2kernelname(self, k):
        return k[0].lower()+k[1:]
    def get_network_address_width(self):
        nnodes = self.number_user_send_ports
        addr_width = int(math.ceil(math.log(nnodes, 2)))
        if 'FORCE_ADDRWIDTH' in self.psn.params:
            #print("Using FORCE_ADDRWIDTH")
            return self.psn.params['FORCE_ADDRWIDTH']
        return addr_width
    
    def getBitWidth(self, count):
        return int(max(1, int(math.ceil(math.log(count, 2)))))

    def get_typetags_count_width(self):
        ntags = len(self.typetags)
        return self.getBitWidth(ntags)
        
    def getranges_tag_and_sourceaddr_info_in_flit(self):
        fw = self.flit_width
        nnodes = self.number_user_send_ports
        addr_width = int(math.ceil(math.log(nnodes, 2)))
        ntags = len(self.typetags)
        tag_width  = int(max(1, int(math.ceil(math.log(ntags, 2)))))
        tag_range = str(addr_width+tag_width-1)+':'+str(addr_width)
        sourceaddr_range = str(addr_width-1)+':0';
        opts_width = 4 
        opts_range = str(opts_width+tag_width+addr_width-1)+':'+str(addr_width+tag_width)
        assert addr_width + tag_width + opts_width <= fw, " #endpoints_addr_width + ln(#ntypes) <= FLIT_DATA_WIDTH "
        return (tag_range, sourceaddr_range, opts_range)
    
    def typename2tag(self, typename):
        if typename in self.typetags:
            return self.typetags[typename]
        else:
            pdb.set_trace()
            raise CompilationError("Unknown type %s" % typename)

    def parse_taskmap_json(self, taskmap_json_file):
        self.original_taskmap_json = collections.OrderedDict(json.load(open(self.taskmap_json_file)))
        x = collections.OrderedDict(json.load(open(self.taskmap_json_file)))
        if 'header' in x:
            hdr = x.pop('header')
            if hdr['multifpga']:
                interfpga_links = x.pop('interfpga_links')
                print("xfpgaLinks:", interfpga_links)
                rmap = collections.OrderedDict()
                for k,v in x.items():
                    rmap.update(v)
                # introduce interfpga link tasks
                for link in interfpga_links:
                    (fromfpga, fromnode), (tofpga, tonode) = link.items()
                    fromlink_tname = '{}_{}'.format(fromfpga, fromnode)
                    tolink_tname = '{}_{}'.format(tofpga, tonode)
                    rmap[fromlink_tname] = fromnode
                    rmap[tolink_tname] = tonode
                    # add to the partition specific map too
                    x[fromfpga][fromlink_tname] = fromnode
                    x[tofpga][tolink_tname] = tonode
                    self.interfpga_links.append((fromfpga, fromnode, tofpga, tonode))
                return rmap, x
        else:
            return x, {}
        return x, {}

    def set_a_task_map(self):
        if self.taskmap_json_file and os.path.exists(self.taskmap_json_file):
            # PARSED earlier
            #self.global_task_map, self.task_partition_map = self.parse_taskmap_json(self.taskmap_json_file) 
            
            #collections.OrderedDict(json.load(open(self.taskmap_json_file)))
            #X self.global_task_map[self.tmodels[0].taskname] = 0
            # off_chip tagged nodes are no special, whatever the taskmap says
            # but should be on the boundaries ideally for phy.impl

            for tm in self.tmodels:
                tm.mapped_to_node = self.global_task_map[tm.taskname]
                #tm.mapped_to_node = self.taskmap[tm.taskname]



        else:
            # some random assignment
            if not self.args.taskmap_use_random:
                random.seed(11) # CONNECT was misbaving for some some shuffles
            nplaces = int(self.psn.params['NUM_USER_SEND_PORTS'])
            # no special nodes as far as random mapping is concerned
            l = [i for i in range(0, nplaces)] # let 0 be the special node, fixed for now
            random.shuffle(l)
            for i, tm in enumerate(self.tmodels):
                tm.mapped_to_node = l[i]
                self.global_task_map[tm.taskname] = l[i]

            if None: # TODO review
                l = [i for i in range(1, nplaces)] # let 0 be the special node, fixed for now
                random.shuffle(l)

                self.tmodels[0].mapped_to_node = 0  # redundant, TODO remove
                self.global_task_map[self.tmodels[0].taskname] = 0

                for i, tm in enumerate(self.tmodels[1:]): # except 0
                    tm.mapped_to_node = l[i]
                    self.global_task_map[tm.taskname] = l[i]


    @property
    def outdir(self):
        return self.args.cgenoutdir
    
    @property
    def taskmap_json_file(self):
        return self.args.taskmap_json_file
    
    def get_project_sha(self): # TODO move
        def is_git_directory(path = '.'):
            return subprocess.call(['git', '-C', path, 'status'], stderr=subprocess.STDOUT, stdout = open(os.devnull, 'w')) == 0    

        def get_repo_sha(repo):
            sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo).decode('ascii').strip()
            return sha

        return 'disabled-sha'
        return get_repo_sha(self.toolroot)
        
        for subdir in os.listdir('.'): # TODO WHAT WAS THIS?!
            if is_git_directory(subdir):
                return get_repo_sha(subdir)
        assert False
    

    def has_off_chip_nodes(self):
        return len(self.get_off_chip_node_id_list())>0
    
    
    def get_tasks_marked_for_exposing_flit_SR_ports(self):
        ll = []
        for t in self.tmodels:
            if t.is_marked_EXPOSE_AS_SR_PORT:
                ll.append((t.mapped_to_node, t.taskname, t.off_chip_qualifier))
        return ll
    def get_tasks_marked_for_exposing_quasiserdes_sr_ports(self):
        ll = []
        for t in self.tmodels:
            if t.is_marked_EXPOSE_AS_XFPGA_SERDES_PORT:
                ll.append((t.mapped_to_node, t.taskname, t.off_chip_qualifier))
        return ll

    def get_off_chip_node_id_list(self):
        ll = []
        for t in self.tmodels:
            if t.is_marked_off_chip:
                ll.append((t.mapped_to_node, t.taskname, t.off_chip_qualifier))
        return ll
    
    @property
    def has_tasks_marked_for_xfpga(self):
        if self.task_partition_map:
            return True
        return False
    def has_tasks_with_qualifier(self, qualname):
        for t in self.tmodels:
            if t.qualifiers:
                if qualname in t.qualifiers:
                    return True
            
        return False

    def get_max_parcel_size(self):
        return 512-512%int(self.flit_width)

    def get_flits_in_type(self, ty):
        return self.get_struct_member_index_ranges_wrt_flitwidth(ty)[0]

    def get_type_size_in_bits(self, ty):
        ty_size = 0
        for n, z, az in self.type_table[ty].member_info_tuples:
            z = z*az
            ty_size += z
        return ty_size

    def get_struct_member_start_pos_for_MPItypes(self, ty):
        d = collections.OrderedDict()
        ty_size = 0
        startpos = 0
        ll = list()
        for n, z, az,mtype in self.type_table[ty].member_n_z_az_ty:
            if mtype not in self.basic_type_list:
                if z <= 64:
                    z = 64
                else:
                    raise NotSupportedException("nonbasic types longer than 64b not presently supported for MPI model")
            z = z*az
            ty_size += z
            endpos = startpos + z - 1
            #ll.append((endpos, startpos, n, az))
            ll.append(startpos)
            startpos = endpos + 1
        return ll
    
    def get_struct_member_index_ranges_wrt_flitwidth(self, ty):
        d = collections.OrderedDict()
        fpaylwidth = int(self.psn.params["FLIT_DATA_WIDTH"])
        ty_size = 0
        startpos = 0
        ll = list()
        for n, z, az in self.type_table[ty].member_info_tuples:
            z = z*az
            ty_size += z
            endpos = startpos + z - 1
            ll.append((endpos, startpos, n, az))
            startpos = endpos + 1
        totalFlits = int((ty_size+fpaylwidth-1)/fpaylwidth)
        return (totalFlits, ll)

    def get_bsv_lib_paths(self):
        l = [self.hls_bviwrappers_outdir]
        if self.has_nonhls_kernels():
            l.append(self.pelib_dir)
        return l

    def get_buffersize_offchipnode(self):
        return 64;

    def find_tmodel_by_name(self, name):
        if not [t for t in self.tmodels if t.taskname == name]:
            pdb.set_trace()
        [tm] = [t for t in self.tmodels if t.taskname == name]
        return tm

    def get_all_communication_arcs(self):
        """
        SRC_stmt::(taskname, stmt_annotation, TypeName, transferAmount) 
        DST_stmt::(taskname, stmt_annotation, TypeName, transferAmount) 
        """
        def srpair_likely_match(src_taskname, s, r):
            if src_taskname in r[3]:
                if s[2].typename == r[2].typename:
#                     return True
                    if r[0] == 'recv' and s[0] == 'send':
                        cnd1 = s[4].fullrange() and (s[2].arraysize == r[2].arraysize)
#                         cnd2 = not s[4].fullrange() and ((s[4].length - s[4].offset) == (r[4].length - r[4].offset))
                        cnd2 = True
                        if cnd1 or cnd2:
                            return True
                        if not cnd2:
                            return False
                    return True
            return False
        srpairs = collections.OrderedDict()

        for tm in self.tmodels:
            srpairs[tm.taskname] = []
            dl = tm.get_unique_message_destinations()
            sl = tm.get_unique_message_sources()
            send_class_stmts = tm.get_send_class_statement_info1()
            if not send_class_stmts and dl: # the placeholder host task
                for dst in dl:
                    dst_tm = self.find_tmodel_by_name(dst)
                    fl = filter(lambda x: tm.taskname in x[3], dst_tm.get_recv_class_statement_info1()) # TODO: let these get_recv/send_class info1 methods do the necessary work 
                    for info_dst_side in fl:
                        # there are no actual send statements in this placeholder so we cook on up
                        reconstructed_src_copy = ('send', info_dst_side[1], info_dst_side[2], [dst_tm.taskname], None) 
                        srpairs[tm.taskname].append((reconstructed_src_copy, info_dst_side, dst_tm.taskname))
            for info in send_class_stmts:
                dst_address_list = info[3]
                for dst in dst_address_list:
                    dst_tm = self.find_tmodel_by_name(dst) 
                    recv_class_stmts = dst_tm.get_recv_class_statement_info1()
                    if not recv_class_stmts:
                        reconstructed_dst_copy = ('recv', info[1], info[2], [tm.taskname], None)
                        srpairs[tm.taskname].append((info, reconstructed_dst_copy, dst_tm.taskname))
                    else:
                        fl = filter(lambda x: srpair_likely_match(tm.taskname, info, x), recv_class_stmts)  
                        for info_dst_side in fl:
                            srpairs[tm.taskname].append((info, info_dst_side, dst_tm.taskname)) 
        rl_srpairs = []
        def _get_nop_fpp(snd, rcv):
            info = snd 
            if not snd[4]: # reconstructed send for placerholder task
                info = rcv
            # flits per packet  # TODO (packet size is fixed in terms of typesize)
            fpp = self.get_flits_in_type(info[2].typename)
            fpp = fpp + 1 # one header flit per packet
            # number of packets
            nop = info[2].arraysize
            if not info[4].fullrange():
                nop = info[4].length - info[4].offset;
            return fpp, nop
        for k, v in srpairs.items():
            for snd, rcv, dst_taskname in v:
                fpp, nop = _get_nop_fpp(snd, rcv)
                def getAnnotation(stmt):
                    if not stmt:
                        return Annotation(name='none',lineno=0,level=0)
                    lno, lvl, name = stmt.get_annotations()[0];
                    return Annotation(name=name, lineno=lno, level=lvl)
                e = Edge(src=Stmt(taskname=k, annotation=getAnnotation(snd[4])),  dst=Stmt(taskname=dst_taskname, annotation=getAnnotation(rcv[4])), fpp=fpp, nop=nop)
                #print(snd[4].get_annotations()[0], ' ==> ', rcv[4].get_annotations()[0], ' : ', dst_taskname)              
                rl_srpairs.append(e)
        return rl_srpairs
    
    def get_line_annotations(self):
        d = collections.OrderedDict()
        for t in self.tdefs_original:
            ll = t.line_annotations()
            for l in ll:
                for e in l:
                    if e[0] in d:
                        d[e[0]].append(e)
                    else:
                        d[e[0]] = [e]
        return d

    def dump_line_annotations(self):
        ispecs_dir = os.path.join(self.outdir, 'ispecs')
        d = self.get_line_annotations()
        with open(os.path.join(ispecs_dir, 'line_annotations.json'), 'w') as fh:
            json.dump(d, fh, indent=4)


    @property
    def basic_type_list(self):
        return na_basic_type_list.keys()
    def to_mpi_typename(self, ty, width=None):
        if ty in na_basic_type_list: 
            return na_basic_type_list[ty][1]
        if width:
            if width <= 64:
                return 'MPI_UNSIGNED_LONG'
            else:
                raise NotSupportedException("nonbasic types longer than 64b not presently supported for MPI model")

#---------------------------------------------------------------------------------------------------






