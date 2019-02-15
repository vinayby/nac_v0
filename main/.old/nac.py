#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# 2015 vby
#############################vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""

"""







class ScatterStmt(TGAstNode):
    def __init__(self, var, var_len, to_dst, **kwargs):
        self.var = var
        self.var_len = var_len
        self.dst_list = to_dst
        super(ScatterStmt, self).__init__(name='scatter', **kwargs)
    
    def _pretty(self):
        return ['\t'*self.depth,self.name," %s:%s TO %r"%(self.var, self.var_len, self.dst_list), '\n']

class DelayStmt(TGAstNode):
    def __init__(self, ccs, **kwargs):
        self.ccs = ccs
        super(DelayStmt, self).__init__(name = 'delay', **kwargs)

class DisplayStmt(TGAstNode):
    def __init__(self, var, **kwargs):
        self.var = var
        super(DisplayStmt, self).__init__(name = 'display', **kwargs)


    
"""
    Visits the STree and Constructs the TG-IR/AST
"""
class TGVisitor(object):
    def __init__(self):
        pass
    





    def delaystmt(self, tree):
        [v] = tree.select('delay_in_ccs > *')
        stmt = DelayStmt(ccs=v)
        info = [tree.depth, tree.index_in_parent]
        return stmt;

    def displaystmt(self, tree):
        [v] = tree.select('param> instance_name > *')
        stmt = DisplayStmt(var=v)
        info = [tree.depth, tree.index_in_parent]
        return stmt;

    def scatter(self, tree):
        (v, vlen, to_dst, vc) = self.send_param_extract(tree)
        stmt = ScatterStmt(var = v, var_len = vlen, to_dst = to_dst)
        info = [tree.depth, tree.index_in_parent]
        return stmt



class PEDeclaration(object):
    def __init__(self, name, parameter_list, qualifiers, v_params, ziplist):
        self.name = name
        self.qualifiers = qualifiers
        self.v_params = v_params
        self.parameter_list = parameter_list ## <- actually,
        self.ziplist = ziplist 
        # remove v_params from parameter_list
        self.parameter_list = [p for p in parameter_list if p not in v_params]
    
    def ioprops(self, pname, tql):
        v = pname
        if v[0] == '&':
            iodir = 'out' # write, def
            v = v[1:]
        else:
            iodir = 'in'  # read, use
        if tql and '__reg__' in tql:
            iodir = 'state'
#             iodir = 'in'
        return (v, iodir)
    @property
    def modname(self):
        # remove __ 
        kn = self.name
        if kn[0:2] == '__':
            kn = kn[2:]
        Kn = kn[0].upper() + kn[1:]
        return Kn

    def iargs(self):
        return [(self.ioprops(p, tql)[0], tname) for (tname, p, tql) in self.parameter_list if self.ioprops(p, tql)[1] == 'in']        
    def oargs(self):
        return [(self.ioprops(p, tql)[0], tname) for (tname, p, tql) in self.parameter_list if self.ioprops(p, tql)[1] == 'out']
    def stateregs(self):
        sr = [(p, tname) for (tname, p, tql) in self.parameter_list if tql and '__reg__' in tql]
        return sr 
        

        




"""
For a given parse tree (stree, here) construct an
AST rooted at each 'task' node.
Return a list of all such task ast's in the input program
"""
def get_task_asts(app_noca):
    tree = get_parse_tree(app_noca)
    #
    # pe declarations
    #
    pe_decl_list = []
    pe_decls = tree.select('=declaration /processing_element/')
    for pd in pe_decls:
        v_param_decl_list = pd.select('=parameter_declaration  /v_param/')
        v_params = []
        for vp in v_param_decl_list:
            ts = vp.select1('type_specifier > *')
            tn = vp.select1('instance_name > *')
            v_params.append((ts, tn))

        #ltq = pd.select('/parameter_type_list/ type_qualifier > *')
        lt_sqn= []
        for x in pd.select('=parameter_declaration '):
            if x.select('/v_param/'):
                continue
            if x.select('storage_class_specifier > *'): # changed from type_qualifier -> storage_class_specifier
                tql = x.select('storage_class_specifier > *')
            else:
                tql = None
            ts = x.select1('type_specifier > *')
            if isinstance(ts, TokValue):
                ts = ts
            else:
                ts = ts.select1('struct_or_union_name > *')
            tn = x.select1('instance_name > *')
            lt_sqn.append((ts, tn, tql))
            pass

#         lts = pd.select('/parameter_type_list/ type_specifier > *')
#         ltn = []
#         for ts in lts:
#             if isinstance(ts, TokValue):
#                 ltn.append(ts)
#             else:
#                 ltn.append(ts.select1('struct_or_union_name > *'))
#         
#         #ltn = pd.select('/parameter_type_list/ struct_or_union_name > *') # if params exclusively structs
#         lin = pd.select('/parameter_type_list/ instance_name > *')
        tquals = pd.select('storage_class_specifier > *')
        pename = pd.select1('init_declarator > instance_name > *')
        
        newts = [d.select('struct_or_union_name>*') for d in pd.select('=parameter_declaration')]
        newtn = [d.select('instance_name>*') for d in pd.select('=parameter_declaration')]
        newtsz = [d.select('size>*') for d in pd.select('=parameter_declaration')]
        newtscs = [d.select('storage_class_specifier>*') for d in pd.select('=parameter_declaration')]

#         pdb.set_trace()
        newtsz = [int(eval(x[0])) if x else 1 for x in newtsz]
        newts =   [x[0] for x in newts]
        newtscs = [x[0] if x else None for x in newtscs]
        newtn =   [x[0] for x in newtn]
        zip4 = list(zip(newts, newtn, newtsz, newtscs))

        #print(list(zip(ltn, lin)))
        pe_decl_list.append(
                PEDeclaration(
                    name=pename,
                  #  parameter_list=list(zip(ltn, lin)),
                    parameter_list=lt_sqn,
                    qualifiers = tquals,
                    v_params= v_params,
                    ziplist=zip4
                    )
                )   


    #global_struct_decls = tree.select('translation_unit > declaration > type_specifier >  *')
    #global_struct_decls = tree.select('translation_unit > declaration > =type_specifier >  /struct_or_union/')
    global_struct_decls = tree.select('translation_unit > declaration > type_specifier > =struct_or_union_specifier > /struct_or_union/')

    struct_types_dict = collections.OrderedDict()
    #print(tree.pretty())
    for gsd in global_struct_decls:
        #print(gsd.pretty())
        gsd.calc_parents()
        gsd.calc_depth()
        a = TGAstBuilder().get(gsd)
        struct_types_dict[a.struct_name] = a

#     struct_types = tree.select('struct')
#     struct_types_dict = collections.OrderedDict()
#     for ty in struct_types:
#       ty.calc_parents()
#       ty.calc_depth()
#       ty_ = ty.select1('=struct /struct_name/')
#       a = TGAstBuilder().get(ty_)
#       struct_types_dict[a.struct_name] = a
# 
    """
    collect global typedefs 
    """
    global_typedefs = tree.select('translation_unit > =declaration > storage_class_specifier > /typedef/')
    for td in global_typedefs:
        print(td.pretty())


    tasks = tree.select('task_definition')
    print ('We have', len(tasks), 'tasks')
    task_asts = []
    for task in tasks:
        task.calc_parents()
        task.calc_depth()
        task_asts.append(TGAstBuilder().get(task))
    
    for a in task_asts:
        a.calc_depth()
        a.calc_index_in_parent()
    
    return (task_asts, struct_types_dict, pe_decl_list)

from .omodel import *
from .codegen import *

def gather_declarations_within_a_task(taskast):
    ld = taskast.get_nodes_with_name('vardef')
    return ld


"""
All variables, within a task, must have unique names (for this
implemenation) even if in different contexts within the task.
"""
def gather_vardefs(taskast):
     # gather declarations
     ld = gather_declarations_within_a_task(taskast)
     instance_to_type_dict = collections.OrderedDict()
     if not ld:
         return (dict(), instance_to_type_dict)
     for a in ld:
         for instance_name, array_size, initializerfile in zip(a.instance_names, a.instance_array_sizes, a.initializerfile):
             instance_to_type_dict[instance_name] = (a.struct_name, [a.attrib, initializerfile], array_size)
     # gather uses ('param' tag wherever it's used)
     lactive = taskast.get_nodes_with_name('param')
     lactive = [a.var for a in lactive if a.kind is not 'v_param'] 
     active_dict = collections.OrderedDict().fromkeys(lactive)
     for k in active_dict.keys():
         active_dict[k] = instance_to_type_dict[k]         

     return (active_dict, instance_to_type_dict)      

def gather_kernels(taskast):
    rl = []
    kl = taskast.get_nodes_with_name("kernel") 
    if kl:
        rl.extend(kl)
    return rl

def topng():
    for arg in sys.argv [1:]:
        r = nocaparse(f=arg);
        print(r)
        r.to_png_with_pydot(r'out.png')
def cpp_pass(nafile):
    # cpp -P -C file.na |tail -n +34
    import subprocess
    cppied_nafile = nafile+"_x_.na"
    process = subprocess.Popen("cpp -P -C "+nafile+" |tail -n +34|tee "+cppied_nafile, shell=True, stdout=subprocess.PIPE)
    return cppied_nafile
    #process.communicate()[0]

def testmain(nafile, options):
    OMX = OModelX(options)
    nafile = cpp_pass(nafile)
    OMX.set_nafile(nafile)
    OMX.read_pregenerated_noc_params()
    (asts, struct_types_dict, OMX.pe_decls) = get_task_asts(nafile)
    OMX.struct_types_dict = struct_types_dict
    for a in asts:
        tm = TaskModel(a)
        (vardefs, var2type_dict) = gather_vardefs(a)
        tm.kernels = gather_kernels(a)
        tm.instance_to_type_dict = var2type_dict
        tm.variabledefinitions(vardefs)
        tm.gom = OMX # global om, a link
        tm.compute_liveness()
        OMX.add_task(tm)

    OMX.set_a_task_map()
    OMX.scan_for_kernels_in_pe_lib()
    bsvcg = BSVCodeGen(OMX, 
            [os.path.join(cmd_folder, d) for d in ['./codegen/templates/bsv', 
             './codegen/templates/connect', './codegen/templates/out_cgen']]
            )
    #bsvcg.pewrappers()
    bsvcg.pewrappers_perdecls()
    OMX.scan_for_kernels_in_pe_lib() # rescan, TODO better
    bsvcg.connect_files()
    bsvcg.tasks_file()

def run():
    parser = ArgumentParser(description='Noc Application Compiler (nocac)')
    parser.add_argument('nafile',  help='the .na file')
    parser.add_argument('--simverbosity', action='store', choices=['state-entry-exit', 'state-exit', 'to-from-network', 'send-recv-trace'], help='Simulation time verbosity')
    parser.add_argument('--nocpath', '-noc', action="store", metavar='NOC_BUILDDIR', dest="noctouse", required=True, help="Path to a Connect NOC build directory")
    parser.add_argument('--outdir', '-odir', action="store", metavar='CODEGEN_OUTDIR', dest="cgenoutdir", required=True, help="Directory for code-generation")
    parser.add_argument('--taskmap', action="store", dest="taskmap_json_file", required=False, help="Task map .json file (corresponding to the NOC chosen)")
    parser.add_argument('--random-taskmap', dest='taskmap_use_random', action='store_true', help='Use a random task mapping (different with each run)' )
    parser.add_argument('--verbose', action='store_true', help='verbose flag')
    parser.add_argument('--dummypes', action='store_true', help='Use dummy pes')
    parser.add_argument('--pewrapers-regen', dest='pewrappers_regen', action='store_true', help='Replace the pewrappers with the newly generated ones')
    parser.add_argument('--fpunits', action='store_true', help='Uses floating point units, flag')
    args = parser.parse_args()
    testmain(args.nafile, args)


# def run1():
#     optparser = OptionParser()
#     #optparser.add_option("-D",dest="define",action="append", default=[],help="Macro Definition")
#     optparser.add_option('--outdir', action="store", dest="cgenoutdir", default="OUT_CGEN", help="Directory for code-generation")
#     optparser.add_option('--usenoc', action="store", dest="noctouse", default="OUT_CGEN/connect", help="Path to a Connect NOC build directory")
#     (options, args) = optparser.parse_args()
#     if args:
#         testmain(args[0], options)
#     else:
#         pass
# 
# if __name__ == '__main__':
#     optparser = OptionParser()
#     optparser.add_option("-D",dest="define",action="append",
#             default=[],help="Macro Definition")
# 
#     (options, args) = optparser.parse_args()
#     if args:
#         testmain(args[0])
#     else:
#         testmain()
