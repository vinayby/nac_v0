#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 2017 vby
############################ vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""

"""

import pdb
import collections
import os, errno
import math
import subprocess
import json

"""
Only symbols within a task.
    No scoping
"""
class symbol_table_entry(object):
    def __init__(self, scs, type_name, array_size, initwith):
        self.scs = scs
        self.type_name = type_name
        self.array_size = array_size 
        self.initwith = initwith 

    @property
    def storage_class(self): # maybe with storage class impl. specs 
        if not self.scs:
            return '__fifo__'
        return self.scs 

    @property
    def typename(self):
        return self.type_name
    
    @property
    def arraysize(self):
        return self.array_size
    @property
    def arraysizewidth(self):
        f = math.log(self.arraysize, 2)
        cf = math.ceil(f)
        return int(cf)
#         if (cf-f) == 0.0:
#             return cf + 1
#         else:
#             return cf 
    
    @property
    def fromfile_initializer(self):
        return self.initwith[1]
    @property
    def has_fromfile_initializer(self):
        if self.initwith and self.initwith[0] == 'fromfile':
            return True 
        return False 


class tmodel(object):
    def __init__(self, task_):
        instanceparams,task = task_
        self._gam = None
        #self.id = task.taskid
        self.task = task 
        self.instanceparams = instanceparams
        self.symbol_table = collections.OrderedDict()
        self.mapped_to_node = None
        self.recv_class_statements = ['recv', 'gather']
        self.send_class_statements = ['send', 'scatter', 'broadcast']

        # temporary
        # if a task has only @any recv address exclusively
        self.iff_use_mergefifo = False 

#         self.name = task.taskname
#         self.qualifiers = task.qualifiers 
    """
        return list of (paramtype, paramname) 
    """
    def get_taskdef_parameters(self,ptype=None):
        paramdecls = self.task.get_nodes_with_name('parameter_declaration')
        ll=[]
        for pd in paramdecls:
            ll.extend([(pd.param_type, pn) for pn in pd.parameter_names])
        if ptype:
            return [a[1] for a in ll if a[0] == ptype]
        return ll
    def get_taskinstance_type_param_value_list(self):
        ol = []
        if not self.is_task_instance():
            return ol
        ldefs = self.get_taskdef_parameters()
        pnvl = self.instanceparams.paramvaluel
        for name, value in pnvl:
            [ptype] = [ld[0] for ld in ldefs if ld[1] == name]
            ol.append((ptype,name,value))
        return ol
    def get_taskinstance_tparam_dict(self):
        l = self.get_taskinstance_type_param_value_list()
        d = collections.OrderedDict()
        for t, p, v in l:
            if t == 'task':
                d[p] = v
        return d


    def is_task_instance(self):
        if self.instanceparams:
            return True
        else:
            return False


    @property
    def qualifiers(self):
        if self.instanceparams:
            return self.instanceparams.qualifiers
        else:
            return self.task.qualifiers
    
    @property
    def off_chip_qualifier(self):
        if self.qualifiers:
            return self.qualifiers[0]
        else:
            return None

    @property
    def is_marked_off_chip(self): # TODO split and rename to marked EXPOSE_AS_FLIT_SR_PORT and EXPOSE_AS_XFPGA_QSERDES_PORT
        off_chip_markers = ['off_chip', 'capi_afu', 'scemi', 'xfpga']
        for m in off_chip_markers:
            if m in self.qualifiers:
                return True
        return False
    @property
    def is_marked_EXPOSE_AS_SR_PORT(self):
        for m in ['off_chip', 'capi_afu', 'scemi']:
            if m in self.qualifiers:
                return True
        return False 
    @property
    def is_marked_EXPOSE_AS_XFPGA_SERDES_PORT(self):
        for m in ['xfpga']:
            if m in self.qualifiers:
                return True
        return False

    @property
    def taskname(self):
        if not self.instanceparams:
            return self.task.taskname
        else:
            return self.instanceparams.taskname
    @property
    def taskdefname(self):
        return self.task.taskname

    @property
    def kernelcalls(self):
        r = []
        kl = self.task.get_nodes_with_name('kernel_call')
        if kl:
            r.extend(kl)
        return r

    def get_loopvar_names_of_loop_statements(self):
        l = self.task.get_nodes_with_name('loopindex')
        return [x.index_var for x in l]

    def get_loop_repeat_statements(self):
        l = self.task.get_nodes_with_name('loop_block')
        ol = []
        for e in l:
            if not e.has_loopindex and e.repeatcount != -1:
                ol.append(e)
        return ol


    def get_send_recv_statements_tagged_pingpong(self):
        l_ = self.task.get_nodes_with_name('recv')
        l_ = l_ + self.task.get_nodes_with_name('send')
        l = [e for e in l_ if 'pingpong' in e.opts]
        return l


    def get_hwkernel_modnames(self):
        modnames = list(map(self._gam.hwkernelname2modname, [k.kernel_name for k in self.kernelcalls]))
        kcallnodes = self.kernelcalls #list(map(self._gam.hwkernelname2modname, [k.kernel_name for k in self.kernelcalls]))
        return list(zip(modnames, kcallnodes))
    
    def get_csv_arguments_for_kernel_for_cpp_model(self, knode):
        extra = []       ## TODOJ move to knode.arguments, essentially add this to the AST
        if not self._gam.args.no_task_info:
            extra.append("task_info")
        
        for d in self._gam.hwkdecls:
            if knode.kernel_name == d.name:
                fromdir = {'in':'', 'out':'&', 'inout':'&'}
                lisarray = [True if e[2]>1 else False for e in d.ziplist] 
                ll = list(map(lambda x: '' if x[1] else fromdir[x[0]], zip(d.iface_iodirs, lisarray)))
                callarguments = extra + knode.argvar_names
                ll = [d+v for d,v in zip(ll,callarguments)]
                return ', '.join(ll)

    def get_csv_arguments_for_kernel(self, modname, knode=None):
        extra = []
        if not self._gam.args.no_task_info:
            extra.append("task_info")

        l = []
        if knode:
            l = knode.arguments
        else:
            for k in self.kernelcalls:
                if self._gam.hwkernelname2modname(k.kernel_name) == modname:
                    l = k.arguments
                    break

        l = extra + [a.var for a in l]
        return ', '.join(l)
        
        
        

    def setup(self):
        self.update_symbol_table(self.task)
        # print('unused symbols', self.find_unused_symbols())

    def update_symbol_table(self, task):

         # gather 'declarations' within a task
         dl = task.get_nodes_with_name('declaration')
         if not dl:
             return
         for d in dl:
             z = zip(d.instance_names, d.instance_array_sizes, d.initwith)
             for n, az, initwith in z:
                 self.symbol_table[n] = symbol_table_entry(d.scs, d.type_name, az, initwith)
         
         unused = self.find_unused_symbols() # remove unused instances
         clean_symbol_table = collections.OrderedDict()
         for k, v in self.symbol_table.items():
             if k not in unused:
                 clean_symbol_table[k]=v
         self.symbol_table = clean_symbol_table 

    def get_dict_instance_symbol_to_number_of_points_of_access(self):
        rcs = self.get_recv_class_statement_info1()
        scs = self.get_send_class_statement_info1()
        ll = rcs + scs
        li = [x[1] for x in ll]
        sendrecv_class_nodes  = [x[4] for x in ll]
        se = set(li)
        d = {}
        for s in se:
            d[s] = 0
        for i in li:
            d[i] += 1
        return d,sendrecv_class_nodes
    

    
    def find_unused_symbols(self): # TODO depr
        usedl = self.task.get_nodes_with_name('msg_object')
        usedl = [m.var for m in usedl if m.kind is 'msg']
        unusedl = list(filter(lambda x: x not in usedl, self.symbol_table.keys()))
        return unusedl

    def get_namelist_of_types(self):
        if self.is_marked_off_chip:
            ic, og = self.get_list_of_types_incoming_and_outgoing()
            s = collections.OrderedDict.fromkeys(list(ic)+list(og)).keys()
            return s
        l = [v.typename for v in self.symbol_table.values()]
        s = collections.OrderedDict.fromkeys(l).keys() # removes dup, but keeps it ordered; unlike set()
        return s

    def get_immediate_blocks(self, wrt_node=None):
        valid_blocks = ["recv", "send", "scatter", "gather", "broadcast", "barrier", "kernel_call", 
                        "loop_block", "displaystmt", "mcopy", "delaystmt", "parallel_block", "group_block",
                        "halt"]
        rl = []
        if not wrt_node:
            """ top level blocks """
            wrt_node = self.task

        for c in wrt_node.children:
            if c.name in valid_blocks:
                rl.append(c)

        return rl

    """
    info1 
    """
    def check_loop_index_from_address(self, node):
        list_loopindex_descrs = []
        def search_up_for_loopcontext(node_):
            p = node_.parent()
            if p.name == 'loop_block' and p.has_loopindex:
                list_loopindex_descrs.append(p.children[0])
            else:
                search_up_for_loopcontext(p)
                     

            
        search_up_for_loopcontext(node)
        rl = []
        for li in list_loopindex_descrs:
            rl.append( (li.index_var, range(li.start_index,li.max_index,li.index_incr)) )

        return rl
    
    def pragma_recvs_info(self):
        l = self.task.get_nodes_with_name('pragma')
        rl = []
        for e in l:
            if e.pragma_name == 'recvs':
                rl.append(e)
        return rl
    
    def pragma_sends_info(self):
        l = self.task.get_nodes_with_name('pragma')
        rl = []
        for e in l:
            if e.pragma_name == 'sends':
                rl.append(e)
        return rl

    def get_recv_class_statement_info1(self):
        info1=[]
        for s in self.recv_class_statements:
            if s == 'barrier':
                continue
            rl = self.task.get_nodes_with_name(s)
            if not rl: 
                continue
            for node in rl:
                if not (node.offset == 0 and node.length == 'all'):
                    #raise NotYetSupportedException("For task graph generation")
                    pass
                
                # TODO get final address_list directly as node.address_list
                address_list_processed = []
                instance_tparams_dict= self.get_taskinstance_tparam_dict()
                for addr in node.address_list:
                    if addr in instance_tparams_dict:
                        address_list_processed.append(instance_tparams_dict[addr])
                    else:
                        address_list_processed.append(addr)
                
                #----------
                if address_list_processed[0][:4] == 'grp_':
                    ll = self.check_loop_index_from_address(node)               
                    idxaddr = address_list_processed[0]
                    taskarrayname = idxaddr[4:idxaddr.find('(')]
                    indexname = idxaddr[idxaddr.find('loopidx_')+len('loopidx_') : idxaddr.find('))')]
                    fl = filter(lambda e: e[0] == indexname, ll)
                    fl = list(fl)
                    assert len(fl) > 0, 'cannot find a loop that uses index: {}'.format(indexname)
                    address_list = []
                    for _, items in fl:
                        address_list.extend(['{}_{}'.format(taskarrayname,i) for i in items])
                    tup = (node.name, node.var, self.symbol_table[node.var], address_list, node)
                    info1.append(tup)
#                     pdb.set_trace()
                else:
                    tup = (node.name, node.var, self.symbol_table[node.var], address_list_processed, node)
                info1.append(tup)
        return info1
    def get_send_class_statement_info1(self, called_from_template=True):
        """
        returns node.name, node.var, symbol_table_entry[var], address_list, node 
        """
        info1=[]
        for s in self.send_class_statements:
            rl = self.task.get_nodes_with_name(s)
            if not rl: 
                continue
            for node in rl:
                if not (node.offset == 0 and node.length == 'all'):
                    #raise NotYetSupportedException("For task graph generation")
                    pass
                
                # TODO get final address_list directly as node.address_list
                address_list_processed = []
                instance_tparams_dict= self.get_taskinstance_tparam_dict()
                for addr in node.address_list:
                    if addr in instance_tparams_dict:
                        address_list_processed.append(instance_tparams_dict[addr])
                    else:
                        address_list_processed.append(addr)
                #----------
                    
                if address_list_processed[0][:4] == 'grp_':
                    ll = self.check_loop_index_from_address(node)               
                    idxaddr = address_list_processed[0]
                    taskarrayname = idxaddr[4:idxaddr.find('(')]
                    indexname = idxaddr[idxaddr.find('loopidx_')+len('loopidx_') : idxaddr.find('))')]
                    fl = filter(lambda e: e[0] == indexname, ll)
                    address_list = []
                    for _, items in fl:
                        address_list.extend(['{}_{}'.format(taskarrayname,i) for i in items])
                    tup = (node.name, node.var, self.symbol_table[node.var], address_list, node)
                    info1.append(tup)
#                     pdb.set_trace()
                else: 
                    tup = (node.name, node.var, self.symbol_table[node.var], address_list_processed, node)
                    info1.append(tup)
        return info1

    def get_list_of_types_incoming_and_outgoing(self):
        ic = []
        og = []
        if self.is_marked_off_chip:
            recvs_pragma = self.pragma_recvs_info()
            sends_pragma = self.pragma_sends_info()
            if recvs_pragma or sends_pragma:
                """
                user explicitly specifies the list of types this
                task is expected to receive and from where (list of addresses)
                """
                for r in recvs_pragma:
                    for ts in r.type_specifier_list:
                        ic.append(ts)
                for s in sends_pragma:
                    for ts in s.type_specifier_list:
                        og.append(ts)
                # remove duplicates without altering order between runs
                ic = collections.OrderedDict().fromkeys(ic).keys()
                og = collections.OrderedDict().fromkeys(og).keys()
                return (ic, og)
            """
                offchip node behaviour, if assumed to be empty/unspecified, we try to infer its IO types.
            """
            # look for all other self._gam.tmodels::get_list_of_types_incoming_and_outgoing to 
            # find what's coming towards this self.taskname and what's being received from here
            for tm in self._gam.tmodels:
                if self.taskname in tm.get_unique_message_destinations():
                    l = tm.get_recv_class_statement_info1()
                    for e in l:
                        symtab_entry = e[2]
                        og.append(symtab_entry.typename)
                if self.taskname in tm.get_unique_message_sources():
                    l = tm.get_send_class_statement_info1()
                    for e in l:
                        symtab_entry = e[2]
                        ic.append(symtab_entry.typename)
            # remove duplicates without altering order between runs
            ic = collections.OrderedDict().fromkeys(ic).keys()
            og = collections.OrderedDict().fromkeys(og).keys()
            return (ic, og)
        
        rl = self.task.get_nodes_with_name("msg_object")
        if not rl:
            return (ic, og)
        for p in rl:
            p.parentspos = p.parent().getpos()
            if p.parent().name in self.recv_class_statements:
                ic.append(self.symbol_table[p.var].typename)
            elif p.parent().name in self.send_class_statements:
                og.append(self.symbol_table[p.var].typename)
        # remove duplicates without altering order between runs
        ic = collections.OrderedDict().fromkeys(ic).keys()
        og = collections.OrderedDict().fromkeys(og).keys()
        return (ic, og)

    def setup_broadcast_stmts(self):
        rl = self.task.get_nodes_with_name("broadcast")
        if rl:
            for x in rl:
#                 x.address_list = [x.taskname for x in self._gam.tmodels if not x.taskname == self.taskname ]
                 x.address_list = [x.taskname for x in self._gam.tmodels ]

    def _taskgroup_address_check(self, _stmt):
        for a in _stmt.address_list:
            if a[0] == '@':
                if a[1:] == 'return':
                    return [a] # handle at the generation time
                if a[1:] == 'any':
                    return [x.taskname for x in self._gam.tmodels if not x.taskname == self.taskname]
                if a[1:] in self._gam.taskgroups:
                    return self._gam.taskgroups[a[1:]].tasknamelist
        return None

    def setup_pragma_recvs_sends_declarations(self):
        ll = self.pragma_recvs_info() + self.pragma_sends_info() 
        for x in ll:
            addr_list = self._taskgroup_address_check(x)
            if addr_list:
                x.address_list = addr_list 
            pass
    
    def setup_gather_taskgroup_stmts(self):
        rl = self.task.get_nodes_with_name("gather")
        if rl:
            for x in rl:
                #print(self.taskname, [x.address_list for x in rl])
                addr_list = self._taskgroup_address_check(x)
                if addr_list:
                    #self.iff_use_mergefifo = True does not apply
                    # but remove self from the list, if present TODO (semantic decision; is this natural?)
                    #x.address_list = [x for x in addr_list if not x == self.taskname]
                    x.address_list = addr_list
    def setup_scatter_taskgroup_stmts(self):
        rl = self.task.get_nodes_with_name("scatter")
        if rl:
            for x in rl:
                #print(self.taskname, [x.address_list for x in rl])
                addr_list = self._taskgroup_address_check(x)
                if addr_list:
                    #self.iff_use_mergefifo = True does not apply
                    # but remove self from the list, if present TODO (semantic decision; is this natural?)
                    #x.address_list = [x for x in addr_list if not x == self.taskname]
                    x.address_list = addr_list
    def setup_send_taskgroup_stmts(self):
        rl = self.task.get_nodes_with_name("send")
        if rl:
            for x in rl:
                #print(self.taskname, [x.address_list for x in rl])
                addr_list = self._taskgroup_address_check(x)
                if addr_list:
                    #self.iff_use_mergefifo = True does not apply
                    # but remove self from the list, if present TODO (semantic decision; is this natural?)
                    #x.address_list = [x for x in addr_list if not x == self.taskname]
                    x.address_list = addr_list

    def setup_recv_taskgroup_stmts(self):
        rl = self.task.get_nodes_with_name("recv")
        if rl:
            for x in rl:
                #print(self.taskname, [x.address_list for x in rl])
                addr_list = self._taskgroup_address_check(x)
                if addr_list:
                    self.iff_use_mergefifo = True
                    # remove self from the list, if present TODO (semantic decision; is this natural?)
                    #x.address_list = [x for x in addr_list if not x == self.taskname]
                    x.address_list = addr_list
#                 if "@any" in x.address_list:
#                     self.iff_use_mergefifo = True
#                     x.address_list = [x.taskname for x in self._gam.tmodels if not x.taskname == self.taskname]
# 
    
    def setup_barrier_group_resolution(self):
        rl = self.task.get_nodes_with_name("barrier")
        if rl:
            for x in rl:
                addr_list = self._taskgroup_address_check(x)
                if addr_list:
                    x.address_list = addr_list


    def get_unique_message_sourcesOLD(self):
        ll = []
        if self.is_marked_off_chip:
            # look for all other self._gam.tmodels::get_list_of_types_incoming_and_outgoing to 
            # find what's coming towards this self.taskname and what's being received from here
            for tm in self._gam.tmodels:
                if tm.taskname == self.taskname:
                    continue
                if self.taskname in tm.get_unique_message_destinationsOLD():
                    ll.append(tm.taskname)
            return ll
        for name in self.recv_class_statements:
            ll.extend(self.task.get_nodes_with_name(name) or [])
        sl=[]
        if not ll:
            return sl
        for e in ll:
            for src in e.address_list:
                sl.append(src)
        #sl = list(set(sl))
        sl = collections.OrderedDict().fromkeys(sl).keys()
        return sl
    def get_unique_message_BLANK(self, BLANK='destinations'):
        ll = []
        if self.is_marked_off_chip:
            #---------------------------------
            #---------------------------------
            recvs_pragma = self.pragma_recvs_info()
            sends_pragma = self.pragma_sends_info()
            """
            user explicitly specifies the list of types this
            task is expected to receive and from where (list of addresses)
            """
            if recvs_pragma and BLANK == 'sources':
                for r in recvs_pragma:
                    for a in r.address_list:
                        ll.append(a)
                return ll  # infer no further
            if sends_pragma and BLANK == 'destinations':
                for s in sends_pragma:
                    for a in s.address_list:
                        ll.append(a)
                return ll  # infer no further
            #---------------------------------
            #---------------------------------
            # look for all other self._gam.tmodels::get_list_of_types_incoming_and_outgoing to 
            # find what's coming towards this self.taskname and what's being received from here
            for tm in self._gam.tmodels:
                if tm.taskname == self.taskname:
                    continue
                look_in = None
                if BLANK == 'destinations':
                    look_in = tm.get_unique_message_sources()
                elif BLANK == 'sources':
                    look_in = tm.get_unique_message_destinations()
                if self.taskname in look_in:
                    ll.append(tm.taskname)
            return ll
        #tup = (node.name, node.var, self.symbol_table[node.var], node.address_list, node)
        sl=[]
        info1_list = None
        if BLANK == 'destinations':
            info1_list = self.get_send_class_statement_info1()
        elif BLANK == 'sources':
            info1_list = self.get_recv_class_statement_info1()
        for name, var, symtab_e, address_list,node in info1_list: # TODO shouldn't address_list always return the apt stuff, instead of this post processing
            ll.extend(self.task.get_nodes_with_name(name) or [])
            sl.extend(address_list)
        sl = collections.OrderedDict().fromkeys(sl).keys()
        return sl
    def get_unique_message_destinations(self):
        return self.get_unique_message_BLANK(BLANK='destinations')
    def get_unique_message_sources(self):
        return self.get_unique_message_BLANK(BLANK='sources')
    def get_unique_message_destinationsOLD(self):
        ll = []
        if self.is_marked_off_chip:
            # look for all other self._gam.tmodels::get_list_of_types_incoming_and_outgoing to 
            # find what's coming towards this self.taskname and what's being received from here
            for tm in self._gam.tmodels:
                if tm.taskname == self.taskname:
                    continue
                if self.taskname in tm.get_unique_message_sourcesOLD():
                    ll.append(tm.taskname)
            return ll
        for name in self.send_class_statements:
            ll.extend(self.task.get_nodes_with_name(name) or [])
        sl=[]
        if not ll:
            return sl
        for e in ll:
            for src in e.address_list:
                sl.append(src)
        #sl = list(set(sl))
        sl = collections.OrderedDict().fromkeys(sl).keys()
        return sl
    def resolve_source_names_(self,sources):
        rs=[]
        _am = self._gam
        for s in sources:
            srcaddr = _am.taskmap(s)
            if not isinstance(srcaddr, int):
                if self.is_task_instance():
                    [pval] = [value for name,value in self.instanceparams.paramvaluel  if name == srcaddr]        
                    srcaddr = _am.taskmap(pval)
                else:
                    pdb.set_trace()
            rs.append(srcaddr)
        return rs

    """
    given a source or destination address -- another task name -- resolve if necessary
    TODO: paramvaluel check for paramtype (only task params here)
    """
    def resolve_address(self,address):
        if isinstance(self._gam.taskmap(address), int):
            return address

        if self.is_task_instance():
            [r] = [value for name, value in self.instanceparams.paramvaluel  if name == address]
            return r
        else:
            return address

    
    def num_flits_in_dispatch_union(self):
        ogty = self.get_list_of_types_incoming_and_outgoing()[1]
        r = max(map(self._gam.get_flits_in_type, ogty))
        return r









