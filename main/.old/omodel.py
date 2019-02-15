#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# 2016 vby
#############################vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""



"""
import pdb
import collections
import os, errno
import math
import subprocess
import json

import nocac.connect_util.connect_util as connect_util


class TaskModel(object):
    def __init__(self, ast):
        self.id = ast.taskid
        self.name = ast.taskname
        self.qualifiers = ast.qualifiers
        self.instance_to_type_dict = collections.OrderedDict() # instance to its attributes (incl. its type)
        self.taskast = ast
        self.mapped_to_node = None
        self.kernels = None
        self.kernels_pelib_info = collections.OrderedDict()
        self.gom = None
        self.liveness = {}
    def get_task_name(self):
        if not self.name:
            return str(self.id)
        else:
            return self.name

    def is_marked_off_chip(self):
        return 'off_chip' in self.qualifiers
    
    def get_pe_decl_portname_instancename_tuple(self, kernNode):
        b = kernNode
        pedecl = self.gom.get_pe_decl(b.kernel_name)
        (i_arg_list, o_arg_list, inorder) = self.get_inout_params_kernel(b)
        iargs = [a.var for a in i_arg_list if a.kind != 'v_param']
        ptl = pedecl.iargs()
        if ptl:
            portnamel, typenamel = zip(*ptl)
            iargs = list(zip(iargs, portnamel, typenamel))
            for inst, pname, tn in iargs:
                if self.get_typename_for_instance(inst) != tn:
                    pdb.set_trace()
                    raise ValueError(inst, 'instance type does not match portname/expected type')
        else:
            iargs = []

        oargs = [a.var for a in o_arg_list ]
        ptl = pedecl.oargs()
        if ptl:
            portnamel, typenamel = zip(*ptl)
            oargs = list(zip(oargs, portnamel, typenamel))
            for inst, pname, tn in oargs:
                if self.get_typename_for_instance(inst) != tn:
                    pdb.set_trace()
                    raise ValueError(inst, 'instance type does not match portname/expected type')

        stateregs = [a.var for a in i_arg_list if a.kind != 'v_param' and self.instance_has_attrib_state(a.var)]
        ptl = pedecl.stateregs()
        if ptl:
            portnamel, typenamel = zip(*ptl)
            stateregs = list(zip(stateregs, portnamel, typenamel))
            for inst, pname, tn in stateregs:
                if self.get_typename_for_instance(inst) != tn:
                    pdb.set_trace()
                    raise ValueError(inst, 'instance type does not match portname/expected type')
        else:
            stateregs = []
        stateregs = [a for a in stateregs if self.instance_has_attrib_state(a[0])] 
        iargs = [a for a in iargs if not self.instance_has_attrib_state(a[0])]
        return (iargs, oargs, stateregs)



    def get_namelist_of_types(self):
        l = [v[0] for v in self.instance_to_type_dict.values()]
        s = collections.OrderedDict.fromkeys(l).keys() # removes dup, but keeps it ordered; unlike set()
        return s

    def get_list_of_types(self):
        ltbyn = self.get_namelist_of_types()
        lt = [self.gom.struct_types_dict[tn] for tn in ltbyn]
        return lt

    def instance_has_attrib_state(self, inst):
        if '__reg__' == self.instance_to_type_dict[inst][1][0]:
            return True
        else:
            return False
    
    def get_typename_for_instance(self, instance):
        return self.instance_to_type_dict[instance][0]

    '''
        returns (typename, [list of attribs])
    '''
    def find_typeinfo(self, instance_name):
        k = instance_name
        is_btype = None 
        bwidth = 0
        typename = None 
        if k in self.instance_to_type_dict:
            is_btype = False
            typename = self.get_typename_for_instance(k)
        else:
            raise ValueError(instance_name,'bit types in this raw form not supported')
            is_btype = True
            v = self.vardefs[k]
            bwidth = v['children'][0].z
            typename = 'Bit#(' + bwidth + ')'
        return (typename, [self.instance_to_type_dict[instance_name][1]], self.instance_to_type_dict[instance_name][2])
    
    def for_pebody_mako_get_kernel_ioargs(self, kmodname):
        rl = self.kernel_specs_list()
        [x] = [r for r in rl if r[0] == kmodname] # only duplicate module instance
        inst_name_csvs = ', '.join([x.var for x in x[1] + x[2]])
        return inst_name_csvs


    """
        returns (modname, ...)
    """
    def kernel_specs_list(self):
        rl = []
        for k in self.kernels:
            (found_pe, pepath, modname) = self.gom.find_pe_in_lib(k.kernel_name)
            (iargs_list, oargs_list, inorder) = self.get_inout_params_kernel(k)
            rl.append( (modname, iargs_list, oargs_list, inorder, found_pe) )
        return rl
    
    def is_this_kernel_output_optional(self, instance_name):
        ll = self.taskast.get_nodes_with_name("sendif")
        for n in ll:
            if n.children[0].var == instance_name:
                return True
        return False

    def get_list_of_types_incoming_and_outgoing(self):
        ic = []
        og = []
        rl = self.taskast.get_nodes_with_name("param")
        if not rl:
            return (ic, og)
        for p in rl:
            p.parentspos = p.parent().getpos()
            if p.parent().name in ['recv']:
                ic.append(self.get_typename_for_instance(p.var))
            elif p.parent().name in ['send', 'scatter', 'sendif']:
                og.append(self.get_typename_for_instance(p.var))
        #ic = list(set(ic))
        #og = list(set(og))
        ic = collections.OrderedDict().fromkeys(ic).keys()
        og = collections.OrderedDict().fromkeys(og).keys()
        return (ic, og)
    
    def get_unique_message_sources(self):
        ll = self.taskast.get_nodes_with_name("recv")
        sl=[]
        if not ll:
            return sl
        for e in ll:
            for src in e.src_list:
                sl.append(src)
        #sl = list(set(sl))
        sl = collections.OrderedDict().fromkeys(sl).keys()
        return sl



    def num_flits_in_dispatch_union(self):
        ogty = self.get_list_of_types_incoming_and_outgoing()[1]
        r = max(map(self.gom.get_flits_in_type, ogty))
        return r


    def get_list_of_types_incoming_and_outgoing_DEL(self):
        raise 
        ic = []
        og = []
        for (modname, iargs, oargs, found_pe) in self.kernel_specs_list():
            ic.extend( [self.get_typename_for_instance(v.var) for v in iargs] )
            og.extend( [self.get_typename_for_instance(v.var) for v in oargs] )
        ic = list(set(ic))
        og = list(set(og))
        return (ic, og)

              


    def get_kernel_modnames(self):
        return [tup[1] for tup in self.kernels_pelib_info.values()]

    def get_kernel_pe_paths(self):
        return [os.path.relpath(tup[0], os.path.join(self.gom.cgoutdir, 'sim')) for tup in self.kernels_pelib_info.values()]
    def get_v_param_assignment_string(self,modname):
        for ks in self.kernel_specs_list():
            if ks[0] == modname:
                return ', '.join([p.passval for p in ks[1] if p.kind == 'v_param'])
        
        return ''
    def get_inout_params_kernel(self, knode):
        il = []
        ol = []
        inorder = []
        for param in knode.children:
#             if self.instance_has_attrib_state(param.var):
#                 il.append(param)
#                 ol.append(param)
#                 continue
            inorder.append(param)
            if param.iodir is 'in':
                il.append(param)
            else:
                ol.append(param)
        return (il, ol, inorder)
    
    def get_var_fmt_specs(self, var):
        typename = self.get_typename_for_instance(var)
        fmtstring = ''
        vliststring = ''
        for n,z in self.gom.struct_types_dict[typename].mnz_pairs:
            if self.instance_has_attrib_state(var):
                vstr = var + '.' + n 
            else:
                vstr = var + '.first.' + n 

            vliststring += vstr + ','
            fmtstring += var + '.' + n + ' = %d '
        # remove last comma
        return (fmtstring, vliststring[0:-1])
 
    """
        crude liveness analysis
          - 1 in edge, 1 out edge
              e.g. loop's etc,. not considered

    """
    def compute_liveness(self):
        rl = self.taskast.get_nodes_with_name("param")
        if not rl:
            return 
        rl = [r for r in rl if r.kind is not 'v_param']
        for p in rl:
            p.parentspos = p.parent().getpos()
            if p.parent().name in ['recv']:
                p.iodir = 'out'
        liveness = {}
        for k in self.vardefs.keys():
            liveness[k] = list()
        for p in rl:
            #print(p.var,p.iodir,p.parentspos)
            #print('possible bug:: is vs ==')
            if p.iodir == 'out':
                liveness[p.var].append(  ('def', p.parentspos, p)  )
            elif p.iodir == 'in':
                liveness[p.var].append(  ('use', p.parentspos, p)  )
            else:
                raise ValueError(p.var,'iodir unset')
        self.liveness = liveness

    def in_a_loop_context_are_we(self, node):
        p = node.parent()
        if p.name == "task":
            return (False, 0, None)
        if p.name in ["loop"]:
            return (True, p.repeatcount, p)
        else:
            return self.in_a_loop_context_are_we(p)



    def is_instance_alive(self, var, position):
        def search_use_def_from(var, xnode):
            for c in xnode.children:
#                 pdb.set_trace()
                if c.name in ['loop']:
#                 if c.name in ['parallel', 'loop']:
                    return search_use_def_from(var, c)
                for (du, pos, p) in self.liveness[var]:
                    if c.getpos() == pos:
                        if du == 'use':
                            return True
                        else:
                            return False
        """
         from the current position, search ahead for a def or use 
            if we are in a loop context 
                if a 'def' comes first (before a 'use') 
                    and this is still inside this loop context
                        return 'dead'
                else 
                    return 'alive'
                we're here as there's nothing ahead, return 'dead'
            else 
                if a 'use' comes first, return 'alive'
                else                    return 'dead'
        """
        if self.instance_has_attrib_state(var):
            # state variables, let's say, are always alive
            return True 
        chain_at = -1
        node = None
        for i,(du, pos, p) in enumerate(self.liveness[var]):
            if pos == position:
                chain_at = i
                node = p

        if chain_at == -1:
            raise ValueError('shoulda found', position, 'in var-du-chain')
        (in_loop, loopcount, loopNode) = self.in_a_loop_context_are_we(node)
        if in_loop:
            for (du, pos, p) in self.liveness[var][ chain_at+1: ]:
                if du == 'def' and self.in_a_loop_context_are_we(p)[0]:
                    return False
                elif du == 'use':
                    return True
                # if we are here, there is nothing ahead, but assume
                # this loop is forever for now and look from the beginning of the
                # loop if it is being used: if yes, declare alive
                #for(du, pos, p) in self.liveness[var][]
            
            ret = search_use_def_from(var, loopNode)
            if ret != None:
                return ret
#             for c in loopNode.children:
#                 #pdb.set_trace()
#                 #return self.is_instance_alive(var, c.getpos())
#                 for (du, pos, p) in self.liveness[var]:
#                     if c.getpos() == pos:
#                         if du == 'use':
#                             return True
#                         else:
#                             return False

            return False
        else:
            for (du, pos, p) in self.liveness[var][chain_at+1:]:
                if du == 'use':
                    return True
                else:
                    return False
            return False
        

        
    def get_immediate_blocks(self, wrt_node=None):
        valid_blocks = ["recv", "send", "scatter", "sendif", "kernel", "loop", "any", "display", "delay", "parallel", "group"]
        rl = []
        if not wrt_node:
            """ top level blocks """
            wrt_node = self.taskast

        for c in wrt_node.children:
            if c.name in valid_blocks:
                rl.append(c)

        return rl

               


    """
     N2S: might as well store the kwargs as vardefs
    """
    def variabledefinitions(self, kwargs):
        if kwargs:
            self.vardefs = collections.OrderedDict(kwargs)
        else:
            self.vardefs = {}

import random
def force_symlink(file1, file2):
    try:
        os.symlink(file1, file2)
    except OSError as e:
        if e.errno == errno.EEXIST:
            os.remove(file2)
            os.symlink(file1, file2)


def trymkdir(dirname):
    try:
        os.mkdir(dirname)
    except OSError as e:
        if e.errno == errno.EEXIST:
            pass
class OModelX(object):
    def __init__(self, args):
        self.nafile_path = None
        self.args = args
        self.cgoutdir = args.cgenoutdir
        self.noctouse = os.path.abspath(args.noctouse)
        self.taskmap_use_random = args.taskmap_use_random
        self.taskmap_json_file = args.taskmap_json_file
        ## setup outdir 
        trymkdir(self.cgoutdir)
        trymkdir(os.path.join(self.cgoutdir, 'src'))
        trymkdir(os.path.join(self.cgoutdir, 'tb'))
        trymkdir(os.path.join(self.cgoutdir, 'sim'))
        trymkdir(os.path.join(self.cgoutdir, 'nalib'))
        force_symlink(self.noctouse, os.path.join(self.cgoutdir, 'connect'))

        self.tm_list = []
        self.struct_types_dict = collections.OrderedDict()
        self.typetags = collections.OrderedDict()
        self.params = collections.OrderedDict()
        self.useSCEMI = True
#         self.specialnodes = {'scemihost':0} # task really, the first task in the file
        self.pelib_dir = None
        self.pe_decls = None
        self.global_task_map = collections.OrderedDict()
    
    def get_pe_decl(self, kernel_name):
        for pd in self.pe_decls:
            if pd.name == kernel_name:
                return pd
    @property
    def num_nodes(self):
        return int(self.params['NUM_USER_SEND_PORTS'])
    
    def has_off_chip_nodes(self):
        return len(self.get_off_chip_node_id_list())>0

    def get_off_chip_node_id_list(self):
        ll = []
        for t in self.tm_list:
            if t.is_marked_off_chip():
                ll.append((t.mapped_to_node, t.get_task_name()))
        return ll

    def get_noc_to_use(self):
        #connect_dir = os.path.join(self.cgoutdir, 'connect')
        connect_dir = self.noctouse
        return connect_dir

    def noc_uses_credit_based_flowcontrol(self):
        connect_dir = self.get_noc_to_use()
        return connect_util.noc_uses_credit_based_flowcontrol(connect_dir)
        
    def get_max_packet_size(self):
        return 512-512%int(self.flit_width())

    def flit_width(self):
        return int(self.params['FLIT_DATA_WIDTH'])
    
    def get_vc_width(self):
        return int(math.ceil(math.log(int(self.params["NUM_VCS"]), 2)))

    def getranges_tag_and_sourceaddr_info_in_flit(self):
        fw = self.flit_width()
        nnodes = int(self.params['NUM_USER_SEND_PORTS'])
        addr_width = int(math.ceil(math.log(nnodes, 2)))
        ntags = len(self.typetags)
        tag_width  = int(max(1, int(math.ceil(math.log(ntags, 2)))))
        tag_range = str(addr_width+tag_width-1)+':'+str(addr_width)
        sourceaddr_range = str(addr_width-1)+':0';
        assert addr_width + tag_width <= fw, " #endpoints_addr_width + ln(#ntypes) <= FLIT_DATA_WIDTH "
        return (tag_range, sourceaddr_range)

    def get_project_sha(self):
        def is_git_directory(path = '.'):
            return subprocess.call(['git', '-C', path, 'status'], stderr=subprocess.STDOUT, stdout = open(os.devnull, 'w')) == 0    

        def get_repo_sha(repo):
            sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo).decode('ascii').strip()
            return sha
        for subdir in os.listdir('.'):
            if is_git_directory(subdir):
                return get_repo_sha(subdir)
        assert False


    def set_nafile(self, naf):
        self.nafile_path = naf
        self.pelib_dir = os.path.join(os.path.dirname(naf), '_pelib')
        if not os.path.exists(self.pelib_dir):
            raise ValueError(self.pelib_dir, 
            """does not exist, please create explicitly or specify a
               directory with a switch
            """)
                

    def get_repo_sha(self):
        repo = os.listdir('.')[0]
        sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo).decode('ascii').strip()
        return sha

#     def isScemiHost(self, nid):
#         return 'scemihost' in self.specialnodes and nid == self.specialnodes['scemihost']
        
    def read_pregenerated_noc_params(self):
        connect_dir = self.get_noc_to_use()
        r = connect_util.get_connect_parameters(connect_dir)
        d = collections.OrderedDict()
        for t2 in r:
            d[t2[0]] = t2[1]
        self.params = d

    def add_task(self, tm):
        self.tm_list += [tm]

    def set_a_task_map(self):
        if self.taskmap_json_file and os.path.exists(self.taskmap_json_file):
            self.global_task_map = collections.OrderedDict(json.load(open(self.taskmap_json_file)))
            #X self.global_task_map[self.tm_list[0].get_task_name()] = 0
            # off_chip tagged nodes are no special, whatever the taskmap says
            # but should be on the boundaries ideally for phy.impl
            
            for tm in self.tm_list:
                tm.mapped_to_node = self.global_task_map[tm.get_task_name()]

        else:
            # some random assignment
            if not self.taskmap_use_random:
                random.seed(11) # CONNECT was misbaving for some some shuffles
            nplaces = int(self.params['NUM_USER_SEND_PORTS'])
            # no special nodes as far as random mapping is concerned
            l = [i for i in range(0, nplaces)] # let 0 be the special node, fixed for now
            random.shuffle(l)
            for i, tm in enumerate(self.tm_list):
                tm.mapped_to_node = l[i]
                self.global_task_map[tm.get_task_name()] = l[i]

            if None: # TODO review
                l = [i for i in range(1, nplaces)] # let 0 be the special node, fixed for now
                random.shuffle(l)

                self.tm_list[0].mapped_to_node = 0  # redundant, TODO remove
                self.global_task_map[self.tm_list[0].get_task_name()] = 0

                for i, tm in enumerate(self.tm_list[1:]): # except 0
                    tm.mapped_to_node = l[i]
                    self.global_task_map[tm.get_task_name()] = l[i]

        with open(os.path.join(self.cgoutdir, 'sim/taskmap.json'), 'w') as fo:
            json.dump(self.global_task_map, fp=fo, indent=4)
        #readback = json.load(open('OUT_CGEN/src/taskmap.json'))
        with open(os.path.join(self.cgoutdir, 'sim/typetags.json'), 'w') as fo:
            self.assign_typetags()
            json.dump(self.typetags, fp=fo, indent=4)
        
        
    def assign_typetags(self):
        for i, t in enumerate(self.struct_types_dict.keys()):
            self.typetags[t] = i

    def typename2tag(self, typename):
        if typename in self.typetags:
            return self.typetags[typename]
        else:
            self.assign_typetags()
            return self.typename2tag(typename)


    def taskmap(self, taskname):
        return self.global_task_map[taskname]

        ## old 
        if self.tm_list[0].mapped_to_node is None:
            self.set_a_task_map()
        
        for t in self.tm_list:
            if t.get_task_name() == taskname:
                return t.mapped_to_node
        return None

    def get_flits_in_type(self, ty):
        return self.new_get_struct_member_index_ranges_wrt_flitwidth(ty)[0]

    def new_get_struct_member_index_ranges_wrt_flitwidth(self, ty):
        d = collections.OrderedDict()
        fpaylwidth = int(self.params["FLIT_DATA_WIDTH"])
        ty_size = 0
        startpos = 0
        ll = list()
        for n, z in self.struct_types_dict[ty].mnz_pairs:
            ty_size += z
            endpos = startpos + z - 1
            ll.append((endpos, startpos, n))
            startpos = endpos + 1
        totalFlits = int((ty_size+fpaylwidth-1)/fpaylwidth)
        return (totalFlits, ll)

#         ## startpos, and endpos are w.r.t flit
#         startpos = 0
#         llo = list()
#         for n, z in self.struct_types_dict[ty].mnz_pairs:
#             endpos = startpos + z - 1
#             start_vindex = int(startpos/fpaylwidth)
#             end_vindex = int(endpos/fpaylwidth)
#             #startpos %= fpaylwidth
#             #endpos   %= fpaylwidth
#             ## list of (idx, endpos, startpos)
#             lli = list()
#             pdb.set_trace()
#             for idx in range(start_vindex, end_vindex+1):
#                 lli.append(  (idx, fpaylwidth-1 if endpos > fpaylwidth else endpos, startpos) )
#                 endpos -= fpaylwidth
#             llo.append(lli)
#             startpos = endpos + 1
#         pdb.set_trace()
#         return llo


            

    def get_struct_member_index_ranges_wrt_flitwidth(self, ty):
        d = collections.OrderedDict()
        startpos = 0
        fdw = int(self.params["FLIT_DATA_WIDTH"])
        for n, z in self.struct_types_dict[ty].mnz_pairs:
            endpos = startpos + z - 1
            vindex = int((startpos)/fdw)
            d[n] = {'vindex':vindex, 'startpos': (startpos % fdw), 'endpos': (endpos % fdw)}
            startpos = endpos + 1
            """
               TODO: when endpos overflows
            """
        return d

    """
    TODO: properly do later
    now return 0 or whatever is set
    """
    def get_vc(self, taskmodel, send_node):
        if send_node.on_vc:
            return send_node.on_vc
        return 0
    
    def find_pe_in_lib(self, kernel_name):
        # remove __  if present
        kn = kernel_name
        if kn[0:2] == '__':
            kn = kn[2:]
        Kn = kn[0].upper() + kn[1:]
        Kfn = Kn + '.bsv'
        p = os.path.join(self.pelib_dir, Kfn)
        return (os.path.exists(p), p, Kn)

    """

    """
    def scan_for_kernels_in_pe_lib(self):
        for tm in self.tm_list:
            if tm.kernels:
                for kr in tm.kernels:
                   (found, p, modname) = self.find_pe_in_lib(kr.kernel_name)
                   if found:
                       tm.kernels_pelib_info[kr.kernel_name] = (p, modname)

