#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 2017 vby
################################################ vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""

"""
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

from .na_utils import *

import os, sys, inspect
import collections
import pdb
""" toolroot:= /PATH/nac/ """
""" toolroot_main:= /PATH/nac/main/ """
toolroot_main = os.path.realpath(
           os.path.abspath(os.path.split(inspect.getfile( inspect.currentframe() ))[0])
        )
toolroot = os.path.abspath(os.path.join(toolroot_main, os.pardir)) 

put_in_python_sys_path(toolroot_main)
put_in_python_sys_path(os.path.join(toolroot_main, 'plyplus'))

from plyplus.plyplus import STransformer,Grammar, is_stree, TokValue
#---------------------------------------------------------------------------------------------------

"""
Paths to resources files relative to toolroot_main, even when used with pyinstaller
    Args:
        relativePath: path to resource files relative to toolroot_main 
    Returns:
        adjusted relativePath considering running as pyinstaller generated bundle
"""
def resourcePath(relativePath):
    try:
        basePath = sys._MEIPASS
    except Exception:
        basePath = os.path.abspath(toolroot_main)

    return os.path.join(basePath, relativePath)

if getattr(sys, 'frozen', False):
    toolroot = resourcePath('.')
 

#---------------------------------------------------------------------------------------------------

def nocaparse(infile, intext, parsedebug):
    if intext:
        na_grammar = Grammar(
                open(resourcePath('grammar/na.grammar')), auto_filter_tokens=True, debug=parsedebug
                ) 
        return na_grammar.parse(intext)
    try:
        return nocaparse(None, open(infile).read(), parsedebug)
    except IOError as e:
        print ("I/O error({0}): {1}".format(e.errno, e.strerror))
        raise e


#---------------------------------------------------------------------------------------------------
import weakref
class NaASTNode(object):
    def __init__(self, name = None, lineinfo = None, **kwargs):
        self.name = name
        self.lineinfo = lineinfo # see get_lineinfo(.)
        self.parent = None
        self.depth = 0
        self.index_in_parent = 0
        self.children = []
        super(NaASTNode, self).__init__(**kwargs)
    
    def add_child(self, child):
        self.children.append(child)


    def calc_depth(self, depth = 0):
        self.depth = depth
        for c in self.children:
            c.calc_depth(depth + 1)

    def calc_index_in_parent(self):
        for i, c in enumerate(self.children):
            try:
                c.calc_index_in_parent()
                c.index_in_parent = i
                c.parent = weakref.ref(self)
            except AttributeError:
                pass

    def getpos(self):
        return (self.depth, self.index_in_parent)
 
    @property
    def lineno(self):
        if not self.lineinfo:
            return 0
        if not None in self.lineinfo:
            return self.lineinfo[0]
        else:
            return 0
    @property
    def stmtuniq_tag(self):
        """
        some unique and readable tag for a statement in terms of lineinfo
        """
        if not None in self.lineinfo:
            mi,mx,col,_ = self.lineinfo
            rs = "{}_{}{}_l{}c{}".format(self.name, self.depth, self.index_in_parent, mi, col)
        else:
            rs = "{}_{}{}".format(self.name, self.depth, self.index_in_parent)
            if self.name != 'halt':
                print("INFO: None in self.lineinfo: ", rs)
        return rs

    def count_nodes_with_name(self, name):
        return len(self.get_nodes_with_name(name))

    def get_nodes_with_name(self, name):
        """
        Returns:
            a list of nodes with `name' under this node
        """
        r_list = []
        for c in self.children:
            x = c.get_nodes_with_name(name)
            if x:
                r_list.extend(x)

        if self.name == name:
            r_list.append(self)
        return r_list

    
    def get_annotations(self):
        """
            Returns:
                List of tuples (stmt_lineno, stmt_depth, stmt_name)
                corresponding to all descendent NaASTNodes
        """
        if len(self.children) == 0:
             return [(self.lineno, self.depth, self.name)]

        l = [(self.lineno, self.depth, self.name)]
        for n in self.children:
            try:
                l.extend(n.get_annotations())
            except AttributeError:
                pass
        return l

    def line_annotations(self, root=None):
        from itertools import chain
        try:
            from itertools import imap
        except ImportError:
            # Python 3...
            imap=map
        if root is None:
            root = self
        root.calc_depth()
        t = (chain(map(lambda x:x.get_annotations() if x else '', root.children)))
        return t
#         for i in t:
#             print (''.join(i))
        #return ''.join(self.get_annotations(**kw))
    # TODO not very useful
    def prettyprint(self, root = None):
        from itertools import chain
        try:
            from itertools import imap
        except ImportError:
            # Python 3...
            imap=map
        if root is None:
            root = self
        root.calc_depth()
        print ('-'*80)
        print (''.join(root._pretty()))
        t = (chain(map(lambda x:x._pretty(), root.children)))
        for i in t:
            print (''.join(i))


    def _pretty(self, indent='\t'):
        StringType = type(u'')
        if len(self.children) == 0:
            return [ indent*self.depth, self.name, '\t', StringType(self), '\n']

        l = [ indent*self.depth, self.name, '\t',  StringType(self), '\n' ]
        for n in self.children:
            try:
                l += n._pretty(indent)
            except AttributeError:
                l += [ indent*(self.depth+1), StringType(n), '\n' ]

        return l

#---------------------------------------------------------------------------------------------------
""" Returns: bit-length of a basic/built-in type """
def basictypes_getsize(type_specifier):
    built_in = {k:v[0] for k,v in na_basic_type_list.items()}
    if type_specifier in built_in:
        return built_in[type_specifier]
    
    if type_specifier.select('bit_equivalent_type > size > *'):
        x = type_specifier.select1('bit_equivalent_type > size > *')
        return eval_num_expr(x)

    x = type_specifier.select('ufixed_type > size > *')
    if x:
        return eval_num_expr(x[0])
    
    raise NotYetSupportedException("Nested struct_or_union_specifier specifiers")

def get_direction_annotation(instancename):
    # the & and @ annotations are a part of the instance name identifier; so index 0
    i = instancename 
    if i[0]=='&': # TODO rf 
        iodir = 'out' # write, def
    elif i[0]=='@':
        iodir = 'inout'
    else:
        iodir = 'in'
    return iodir

class HWKernelDeclaration(object):
    def __init__(self, name, tq, ziplist, iface_iodirs):
        self.name = name
        self.ziplist = ziplist
        self.tq = tq
        self.iface_iodirs = iface_iodirs 
    
    @property
    def modname(self):
        x = self.name
        x = x[0].upper() + x[1:]
        return x
    def get_interface_directions_list(self):
        pass

#---------------------------------------------------------------------------------#
#---- AST Nodes ------------------------------------------------------------------#
#---------------------------------------------------------------------------------#
class struct_or_union_specifier(NaASTNode):
    def __init__(self, struct_name, **kwargs):
        self.struct_name = struct_name
        self._member_info_tuples = None
        self._member_n_z_az_ty = None
        self.has_non_standard_types_ = False
        super().__init__(name='struct', **kwargs) # TODO name it different?
    
    """
    return a list the same size of member_info_tuples
    """
    @property
    def basictypes(self):
        btl = []
        for sdecln in self.children:
            if sdecln.name == 'struct_declaration':
                mn = sdecln.member_names 
                if is_stree(sdecln.type_specifier):
                    ufixed_type_tuple = sdecln.type_specifier.select('ufixed_type > size > *')
                    if ufixed_type_tuple:
                        btl.extend(['ap_ufixed<{},{}>'.format(*ufixed_type_tuple)]*len(mn))
                    else:
                        btl.extend([None]*len(mn))
                else:
                    if sdecln.type_specifier in na_basic_type_list.keys():
                        btl.extend([sdecln.type_specifier]*len(mn))
                    else:
                        btl.extend([None]*len(mn))
        return btl

    def mpi_compatible_types(self):
        pass
    

    @property # TODO rf
    def member_info_tuples(self):
        if self._member_info_tuples:
            return self._member_info_tuples
        mnz = []
        for sdecln in self.children:
            if sdecln.name == 'struct_declaration':
                mz = basictypes_getsize(sdecln.type_specifier)
                mn = sdecln.member_names 
                maz = sdecln.member_array_sizes
                mnz.extend(zip(mn, [mz]*len(mn), maz))

                
        self._member_info_tuples = mnz
        return mnz
    
    @property
    def has_non_standard_types(self):
        _ = self.member_n_z_az_ty 
        return self.has_non_standard_types_

    @property # TODO rf
    def member_n_z_az_ty(self):
        if self._member_n_z_az_ty:
            return self._member_n_z_az_ty
        mnz = []
        for sdecln in self.children:
            if sdecln.name == 'struct_declaration':
                mz = basictypes_getsize(sdecln.type_specifier)
                mn = sdecln.member_names 
                maz = sdecln.member_array_sizes
                mty = sdecln.type_specifier
                if is_stree(mty):
                    ufixed_type_tuple = mty.select('ufixed_type > size > *')
                    self.has_non_standard_types_ = True
                    if ufixed_type_tuple:
                        mty = 'ufixed'
                    elif mty.select('bit_equivalent_type > size > *'):
                        mty = 'bits'
                    else:
                        pdb.set_trace()
                        mty = None
                mnz.extend(zip(mn, [mz]*len(mn), maz, [mty]*len(mn)))

                
        self._member_n_z_az_ty = mnz
        return mnz
 
    def _pretty(self):
        return ['\t'*self.depth, self.name, self.struct_name, str(self.nz_dict)]

class struct_declaration(NaASTNode):
    def __init__(self, data, **kwargs):
        ts, inl, zl = data
        self.type_specifier = ts
        self.member_names = inl
        self.member_array_sizes = zl
        super(struct_declaration, self).__init__(name='struct_declaration', **kwargs)

class task_group(NaASTNode):
    def __init__(self, data, **kwargs):
        taskgroupname, tasknamelist = data
        self.tasknamelist = list(tasknamelist)
        self.taskgroupname = taskgroupname
        super(task_group, self).__init__(name='task_group',**kwargs) 

class task_instance(NaASTNode):
    def __init__(self, data, **kwargs):
        tid, taskname, num_task_instances, taskdefname, qualifiers, paramvaluel = data
        self.taskid = tid;
        self.taskname = taskname
        self.num_task_instances = num_task_instances
        self.taskdefname = taskdefname
        self.qualifiers = qualifiers
        self.paramvaluel = paramvaluel
        super(task_instance, self).__init__(name='task_instance',**kwargs) 
    
    @property
    def is_array_declaration(self):
        return self.num_task_instances is not None

    def generate_instance_names(self):
        assert self.is_array_declaration, "This is only called on a task instance AST node, defined as an array"
        l = ['{}_{}'.format(self.taskname, i) for i in range(self.num_task_instances)]

        return l

class task_definition(NaASTNode):
    def __init__(self, data, **kwargs):
        tid, taskname, qualifiers = data
        self.taskid = tid;
        self.taskname = taskname
        self.qualifiers = qualifiers
        super(task_definition, self).__init__(name='task_definition',**kwargs) 

    """
        if marked virtual, then expect explicit task_instance

        Unintialized parameters, sure, but even
        if default parameters are all completely specified, explicit task_instance 
        is expected
    """
    def is_completely_specified(self):
        if 'virtual' in self.qualifiers:
            return False
        if self.get_nodes_with_name('parameter_declaration'):
            return False
        else:
            return True

class declaration(NaASTNode): 
    def __init__(self, data, **kwargs):
        tn,inl,zl,initl,scs = data
        self.type_name = tn
        self.instance_names = inl
        self.instance_array_sizes = zl
        self.scs = scs
        self.initwith = initl
        super(declaration, self).__init__(name='declaration',**kwargs) 
    def __repr__(self):
        return '<scs {} typename {} instance_names {} instance_array_sizes {} >'.format(self.scs,self.type_name,self.instance_names,self.instance_array_sizes)

class parameter_declaration(NaASTNode): 
    def __init__(self, data, **kwargs):
        pt,pnl,initl = data
        self.param_type = pt
        self.parameter_names = pnl
        self.initwith = initl
        super(parameter_declaration, self).__init__(name='parameter_declaration',**kwargs) 

class pragma(NaASTNode): # only supports :recvs and :sends pragmas now
    def __init__(self, data, **kwargs):
        pragma_name, tsl = data
        self.pragma_name = pragma_name
        self.type_specifier_list = tsl
        self.address_list_ = None  
        super(pragma, self).__init__(name='pragma', **kwargs)

    @property                      # TODO just replicating from recv/send now
    def address_list(self):
        if self.address_list_:
            return self.address_list_
        r = self.get_address_list()
        return r
    @address_list.setter
    def address_list(self, value):
        self.address_list_ = value

    def get_address_list(self):
        l = self.get_nodes_with_name('address')
        ol = []
        for a in l:
            if a.address_index:
                ol.append('grp_{}((loopidx_{}))'.format(a.address, a.address_index)) # TODO clean
            else:
                ol.append(a.address)
        return ol

class recv(NaASTNode):
    def __init__(self, data, **kwargs):
        var, address_list, offset, length, opts = data
        self.var = var
        self.offset = offset
        self.length = length
        self.address_list_ = None
        self.opts = opts
        super(recv, self).__init__(name='recv', **kwargs)
    @property
    def address_list(self):
        if self.address_list_:
            return self.address_list_
        r = self.get_address_list()
        return r
    @address_list.setter
    def address_list(self, value):
        self.address_list_ = value

    def get_address_list(self):
        l = self.get_nodes_with_name('address')
        ol = []
        for a in l:
            if a.address_index:
                ol.append('grp_{}((loopidx_{}))'.format(a.address, a.address_index)) # TODO clean
            else:
                ol.append(a.address)
        return ol
    def fullrange(self):
        if self.offset == 0 and self.length == 'all':
            return True
        return False

class send(NaASTNode):
    def __init__(self, data, **kwargs):
        var, address_list, offset, length,opts = data
        self.var = var
        self.offset = offset
        self.length = length
        self.address_list_ = None
        self.opts = opts
        super(send, self).__init__(name='send', **kwargs)
    @property
    def address_list(self):
        if self.address_list_:
            return self.address_list_
        r = self.get_address_list()
        return r
    @address_list.setter
    def address_list(self, value):
        self.address_list_ = value

    def get_address_list(self):
        l = self.get_nodes_with_name('address')
        ol = []
        for a in l:
            if a.address_index:
                ol.append('grp_{}((loopidx_{}))'.format(a.address, a.address_index)) # TODO clean
            else:
                ol.append(a.address)
        return ol
    def fullrange(self):
        if self.offset == 0 and self.length == 'all':
            return True
        return False

class address(NaASTNode):
    def __init__(self, data, **kwargs):
        self.address, self.address_index = data
        super(address, self).__init__(name='address', **kwargs)
        
class gather(NaASTNode):
    def __init__(self, data, **kwargs):
        var, address_list, offset, length, opts = data
        self.var = var
        self.address_list = address_list
        self.offset = offset
        self.length = length
        self.opts = opts
        super(gather, self).__init__(name='gather', **kwargs)

class scatter(NaASTNode):
    def __init__(self, data, **kwargs):
        var, address_list, offset, length = data
        self.var = var
        self.address_list = address_list
        self.offset = offset
        self.length = length
        super(scatter, self).__init__(name='scatter', **kwargs)
    def fullrange(self):
        return True

class broadcast(NaASTNode):
    def __init__(self, data, **kwargs):
        var, offset, length = data
        self.var = var
        self.offset = offset
        self.length = length
        self.address_list = ["all_nodes_placeholder"]
        super(broadcast, self).__init__(name='broadcast', **kwargs)

class barrier(NaASTNode):
    def __init__(self, data, **kwargs):
        address_list,groupname = data
        self.groupname = groupname
        self.address_list = address_list
        super(barrier, self).__init__(name='barrier', **kwargs)

class loop_block(NaASTNode):
    def __init__(self, data, **kwargs):
        self.repeatcount, self.has_loopindex = data
        super(loop_block, self).__init__(name='loop_block', **kwargs)

class loopindex(NaASTNode):
    def __init__(self, data, **kwargs):
        self.index_var, self.start_index, self.max_index, self.index_incr = data
        super(loopindex, self).__init__(name='loopindex', **kwargs)

class msg_object(NaASTNode):
    def __init__(self, data, **kwargs):
        kind, var, iodir = data
        self.kind = kind
        self.var = var
        self.iodi = iodir # TODO  not used?
        super(msg_object, self).__init__(name='msg_object', **kwargs)
    def __repr__(self):
        return ' <var {}>'.format(self.var)

class parallel_block(NaASTNode):
    def __init__(self, **kwargs):
        super(parallel_block, self).__init__(name='parallel_block', **kwargs)

class group_block(NaASTNode):
    def __init__(self, **kwargs):
        super(group_block, self).__init__(name='group_block', **kwargs)

class kernel_call(NaASTNode):
    def __init__(self, data, **kwargs):
        kernel_name = data
        self.kernel_name = kernel_name
        super(kernel_call, self).__init__(name='kernel_call', **kwargs)
    @property
    def arguments(self):
        al = self.get_nodes_with_name('msg_object')
        return al
    @property
    def argvar_names(self):
        al = self.arguments
        al = [a.var for a in al]
        al = [e[1:] if e[0] == '&' else e  for e in al ]
        return al
    def __repr__(self):
        return self.kernel_name 

class delaystmt(NaASTNode):
    def __init__(self, data, **kwargs):
        delayccs = data
        self.delayccs = delayccs
        super(delaystmt, self).__init__(name='delaystmt', **kwargs)

class displaystmt(NaASTNode):
    def __init__(self, data, **kwargs):
        var, offset, length = data
        self.var = var
        self.offset = offset
        self.length = length
        super(displaystmt, self).__init__(name='displaystmt', **kwargs)

class mcopy(NaASTNode):
    def __init__(self, data, **kwargs):
        mfrom, mto, offset, length = data
        self.varfrom = mfrom 
        self.varto = mto 
        self.offset = offset
        self.length = length
        super(mcopy, self).__init__(name='mcopy', **kwargs)

class halt(NaASTNode):
    def __init__(self, data,  **kwargs):
        self.signum = data
        super(halt, self).__init__(name='halt', **kwargs)

#---------------------------------------------------------------------------------#
"""
Calc transform
"""
import operator as op

calc_grammar = Grammar("""
    start: add;

    // Rules
    ?add: (add add_symbol)? mul;
    ?mul: (mul mul_symbol)? atom;
    @atom: neg | number |identifier| '\(' add '\)';
    neg: '-' atom;

    // Tokens
    identifier:  '[a-zA-Z_][0-9a-zA-Z_]*';
    number: '[\d.]+';
    mul_symbol: '\*' | '/';
    add_symbol: '\+' | '-';

    WS: '[ \t]+' (%ignore);
""")
class Calc(STransformer):
 
    def _bin_operator(self, exp):
        arg1, operator_symbol, arg2 = exp.tail
 
        operator_func = { '+': op.add, 
                          '-': op.sub, 
                          '*': op.mul, 
                          '/': op.truediv }[operator_symbol]
 
        if isinstance(arg1, int) and isinstance(arg2, int):
            return operator_func(arg1, arg2)
        else:
            return '({}{}{})'.format(arg1,operator_symbol, arg2)    
 
    number      = lambda self, exp: int(exp.tail[0])
    neg         = lambda self, exp: -exp.tail[0]
    identifier  = lambda self, exp: 'loopidx_{}'.format(exp.tail[0])
    __default__ = lambda self, exp: exp.tail[0]
 
    add = _bin_operator
    mul = _bin_operator
#---------------------------------------------------------------------------------#
"""
"""
class NaVisitor(object):
    def __init__(self):
        pass
    def get_lineinfo(self, T):
        return (T.min_line, T.max_line, T.min_col, T.max_col)
    def struct_or_union_specifier(self, T):
        name, *tail = T.select('struct_or_union_specifier > struct_or_union_name > *')
        return struct_or_union_specifier(name, lineinfo=self.get_lineinfo(T))

    """
    Only case 1 is handled. (i.e. No nested structures, for now.)
    --------------------------------------------------------------------------------
    Case 1                                    Case 2
    --------------------------------------------------------------------------------
    struct_declaration                      struct_declaration
      type_specifier        uint32_t          type_specifier
      struct_declarator_list                    struct_or_union_specifier
        struct_declarator                         struct_or_union   struct
          instance_name     a                     struct_or_union_name      SubPair
        struct_declarator                         struct_declaration
          instance_name     b                       type_specifier  uint8_t
                                                    struct_declarator_list
                                                      struct_declarator
                                                        instance_name       e1
                                                      struct_declarator
                                                        instance_name       e2
                                              struct_declarator_list
                                                struct_declarator
                                                  instance_name     v1
    --------------------------------------------------------------------------------
    """
    def struct_declaration(self, T):
        try:
            ts  = T.select1('type_specifier > *') 
 
            inl = T.select('struct_declarator > instance_name > *')
            zl  = T.select('array_size > size > *') 
            zl  = [eval_num_expr(z) if not is_stree(z) else int(Calc().transform(z)) for z in zl]
            
            #print(inl, ts, zl)
            if zl and len(inl) != len(zl):
                raise NotYetSupportedException("Mixing a[n]'s with b's")

            if not zl:
                zl = [1]*len(inl)

        except Exception as e:
            print("Case not handled:: ", e)
            print(T.pretty()) # TODO : pass T to NotYetSupportedException
            sys.exit()

        return struct_declaration((ts, inl, zl), lineinfo=self.get_lineinfo(T))
    

    def parameter_declaration(self, T):
        [pt] = T.select('paramtype > *')
        pnl = T.select('instance_name > *')
        initl = None
        if T.select('initializer > *'):
            initl = T.select('initializer >  taskname_val > *')
        if not initl:
            initl = [(None)]*len(pnl)
        x = (pt, pnl, initl)
        return parameter_declaration(x, lineinfo=self.get_lineinfo(T))




    """
    Assuming this is under a task_definition 
    """
    def declaration(self, T):
        tn = T.select('struct_or_union_name > *')
        if not tn: # either 'struct X ...' or 'float ...'
            tn = T.select('type_specifier > *')
        inl = T.select('instance_name > *')
        zl  = T.select('array_size > size > *') 
        zl  = [eval_num_expr(z) for z in zl]
        if zl and len(inl) != len(zl):
            raise NotYetSupportedException("Mixing a[n]'s with b's")

        if not zl:
            zl = [1]*len(inl)

        scs = T.select('storage_class_specifier > *') or [None]
        scs = scs[0]
        tn = tn[0]

        # TODO rf
        initl = None
        if T.select('initializer > *'):
            #initl = T.select('initializer > filename > string > *')
            initlfnamestring = T.select('initializer > filename> string > *')
            initlfnameparam = T.select('initializer >  paramname > *')
            initl = [('fromfile', x) for x in initlfnamestring]
            initl += [('fromfile', x) for x in initlfnameparam]
        if not initl:
            initl = [(None, None)]*len(inl)

        x = (tn,inl,zl,initl,scs)
        return declaration(x, lineinfo=self.get_lineinfo(T)) 
    

    def msg_object(self, T):
        i = T.select1('instance_name > *')
#         offset = 0
#         length = 'all'
#         if T.select('index>*'):
#             offset = int(T.select1('index>*'))
#             if not i[0]  == '&':
#                 length = 0
#         if T.select('length>*'):
#             length = int(T.select1('length>*'))
#         

        if T.select('/passed_value/'):
            raise NotYetSupportedException("passing parameters")
        iodir = get_direction_annotation(i)
        if iodir in ['out', 'inout']:
            i=i[1:]
        x = ('msg', i, iodir)
        return msg_object(x, lineinfo=self.get_lineinfo(T))    

    def task_group(self, T):
        tnl = T.select('task_group > taskname_csl > taskname > *')
        [tgn] = T.select('task_group > taskgroupname > *')
        x = (tgn, tnl)
        return task_group(x, lineinfo=self.get_lineinfo(T))
    
    def task_instance(self, T):
        [tid] = T.select('taskid > *') or [None]
        [taskname] = T.select('task_instance > taskname > *')
        num_task_instances = None
        if T.select('taskcount'):
            taskcount = T.select1('taskcount>*')
            taskcount = eval_num_expr(taskcount)
            num_task_instances = taskcount

        [taskdefname] = T.select('task_instance > taskdefname > *')
        qualifiers = T.select('task_instance > task_qualifier > *')
        pnl = T.select('paramname>*')
        vnl = T.select('valname>*')
        # unhandled cases, #1
        vnl = [x if not is_stree(x) else x.select1('string>*') for x in vnl ]
        paramvaluel = list(zip(pnl,vnl))
        x = (tid, taskname, num_task_instances, taskdefname, qualifiers, paramvaluel)
        return task_instance(x, lineinfo=self.get_lineinfo(T))


    def task_definition(self, T):
        [tid] = T.select('taskid > *') or [None]
        [taskname] = T.select('task_definition > taskname > *')
        qualifiers = T.select('task_definition > task_qualifier > *')
        x = (tid, taskname, qualifiers)
        return task_definition(x, lineinfo=self.get_lineinfo(T))

    def delaystmt(self, T):
        delayccs = T.select1('delay_in_ccs>*')
        delayccs = eval_num_expr(delayccs)
        x = delayccs
        return delaystmt(x, lineinfo=self.get_lineinfo(T))
    
    def halt(self, T):
        # TODO: line not apparently set for this statement (plyplus quirk)
        signum = None 
        if T.select('signum>*'):
            signum = T.select1('signum>*')
        x = signum 
        return halt(x, lineinfo=self.get_lineinfo(T));

    """
        default offset is 0
        default length is 'all'
    """
    def _get_offset_and_length(self, T):
        offset = 0
        length = 'all'
        if T.select('offset>*'):
            offset = T.select1('offset>*')
#             offset = Calc().transform(calc_grammar.parse(offset)) 
            offset = eval_num_expr(offset)
            if T.select('length>*'):
                length = eval_num_expr(T.select1('length>*'))
            else:
                print("NOTE: reverting to default length=all when o-specified-but-not-l")
        return offset, length

    def displaystmt(self, T):
        [i] = T.select('msg_object > instance_name > *')
        
        offset, length = self._get_offset_and_length(T)

        x = (i, offset, length)
        return displaystmt(x, lineinfo=self.get_lineinfo(T))
    
    def mcopy(self, T):
        mfrom, mto = T.select('msg_object > instance_name > *')
        offset, length = self._get_offset_and_length(T)

        x = (mfrom, mto, offset, length)
        return mcopy(x, lineinfo=self.get_lineinfo(T))

    def recv(self, T):
        i = T.select1('msg_object > instance_name > *')
        address_list = T.select('address > taskname > *') 
        
        offset, length = self._get_offset_and_length(T)
        
        if T.select('address > taskid > *'):
            raise NotYetSupportedException('Sending to taskid')
        
        opts = T.select('coord_option > *')

        # nacchecks 
        if 'pingpong' in opts and length == 'all':
            raise NotSupportedException(" specify both offset and length when using pingpong option")
        
        x = (i,address_list, offset, length, opts)        
        return recv(x, lineinfo=self.get_lineinfo(T))
    
    def address(self, T):
        addr = T.select1('address > taskname > *')
        other = T.select('address>  loopidx  > *')
        addr_idx = None 
        if other:
            addr_idx = other[0]

        x = (addr, addr_idx)
        return address(x)
    
    def pragma(self, T):
        pragma_name = T.select1('pragma_option > *')
        type_specifier_list = T.select('struct_or_union_name > *')
        x = (pragma_name, type_specifier_list)
        return pragma(x, lineinfo=self.get_lineinfo(T))
    
    def send(self, T):
        i = T.select1('msg_object > instance_name > *')
        address_list = T.select('address > taskname > *') 
        
        
        offset, length = self._get_offset_and_length(T)
        
        if T.select('address > taskid > *'):
            raise NotYetSupportedException('Sending to taskid')
        
        if T.select('vchannel > *'):
            raise NotYetSupportedException('vchannel looks clumsy')
        
        opts = T.select('coord_option > *')
        
        x = (i,address_list, offset, length, opts)
        return send(x, lineinfo=self.get_lineinfo(T))
    
    def broadcast(self, T):
        i = T.select1('msg_object > instance_name > *')
        
        offset, length = self._get_offset_and_length(T)
        
        x = (i, offset, length)
        return broadcast(x, lineinfo=self.get_lineinfo(T))

    def barrier(self, T):
        address_list = T.select('address > taskname > *') 
        
        groupname = None
        if len(address_list) == 1 and address_list[0][0] == '@':
            groupname = address_list[0][1:]

        x = address_list, groupname
        return barrier(x, lineinfo=self.get_lineinfo(T))

    def gather(self, T):
        i = T.select1('msg_object > instance_name > *')
        address_list = T.select('address > taskname > *') 
        
        offset, length = self._get_offset_and_length(T)
        if T.select('address > taskid > *'):
            raise NotYetSupportedException('Sending to taskid')
        
        opts = T.select('coord_option > *')
        x = (i,address_list, offset, length, opts)
        return gather(x, lineinfo=self.get_lineinfo(T))

    def scatter(self, T):
        i = T.select1('msg_object > instance_name > *')
        address_list = T.select('address > taskname > *') 
        
        if T.select('address > taskid > *'):
            raise NotYetSupportedException('Sending to taskid')
        
        if T.select('vchannel > *'):
            raise NotYetSupportedException('vchannel looks clumsy')
        
        offset, length = self._get_offset_and_length(T)
        x = (i,address_list, offset, length)
        return scatter(x, lineinfo=self.get_lineinfo(T))
    
    def parallel_block(self, T):
        return parallel_block(lineinfo=self.get_lineinfo(T))
    
    def group_block(self, T):
        return group_block(lineinfo=self.get_lineinfo(T))
    
    def loopindex(self,T):
        [start_index] = T.select('loop_start_index > size > *') or [0]
        [max_index] = T.select('loop_max_index > size > *') or [-1]
        [index_incr] = T.select('loop_incr > size > *') or [1]
        [index_var] = T.select('loopidx > *')
        l = (index_var, eval_num_expr(start_index), eval_num_expr(max_index), eval_num_expr(index_incr))
        return loopindex(l, lineinfo=self.get_lineinfo(T))



    def loop_block(self, T):
        immT = T.tail[0]

        repeatcount = -1
        if immT.head == 'loopcount':
            repeatcount = immT.select('loopcount > size > *')[0] or [-1]
        
        has_loopindex = False
        if immT.head == 'loopindex':
            has_loopindex = True
        l = (eval_num_expr(repeatcount), has_loopindex)
        return loop_block(l, lineinfo=self.get_lineinfo(T))
    
    def kernel_call(self, T):
        n = T.select1('kernel_call > kernel_name > *')
        x = n
        return kernel_call(x, lineinfo=self.get_lineinfo(T))


#---------------------------------------------------------------------------------#
class NaASTBuilder(NaVisitor):
    def __init__(self):
        self.astroot = NaASTNode(name='start') 
        super(NaVisitor, self).__init__()

    def prettyprint(self):
        from itertools import chain
        try:
            from itertools import imap
        except ImportError:
            # Python 3...
            imap=map
        self.astroot.calc_depth()
        print ('-'*80)
        print (''.join(self.astroot._pretty()))
        t = (chain(imap(lambda x:x._pretty(), self.astroot.children)))
        for i in t:
            print (''.join(i))

    
    def count_nodes_with_name(self, name):
        count = 0
        if (self.name == name):
            return 1
 
        if not self.children:
            return 0

        for c in self.children:
            count += c.count_nodes_with_name(name)
        return count

    def get(self, tree):
        l = self._traverse(tree, self.astroot)
        self.astroot = l
        return self.astroot
 
    def _traverse(self, tree, ast):
# Leave ungathered items that have already
# been gathered: TokenValues, and those attr's 
# that have not been defined in self
        if isinstance(tree, TokValue):
            return
        h = getattr(self, tree.head, self.__default__)(tree)
        if not h:
            return
# A legal h, here, is going to be the parent of
# its legal kids as returned from a recursive traverse
        for i, kid in enumerate(tree.tail):
            l = self._traverse(kid, h)
            if l: 
                h.add_child(l)
# The family tree headed by 'h', at this stage, is all complete
        return h

    def __default__(self, tree):
        pass
#---------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------#
#---------------------------------------------------------------------------------#
def get_parse_tree(nafile, naparse_debug):
    return nocaparse(os.path.join('', nafile), None, naparse_debug)

"""
Construct and return a list of all nodes of type nac.struct_or_union_specifier
"""
def glean_type_declaration_nodes(T):
    sou_decls = T.select('translation_unit > declaration > type_specifier > =struct_or_union_specifier > /struct_or_union/')
    sous_list = []
    for sou in sou_decls:
        sou.calc_parents()
        sou.calc_depth()
        sou.calc_position()
        a = NaASTBuilder().get(sou)
        sous_list.append(a)
    return sous_list

import copy 
def glean_task_instances(T):
    """Collect task_instance nodes from the parse tree
       Return:
            (til_expanded, til)
            til_expanded:   FLAT list of task instances (unroll array instances)
            til:            AST-level list of task instance nodes 
    """
    taskinstances = T.select('task_instance')
    til = []
    for ti in taskinstances:
        ti.calc_position()
        til.append(NaASTBuilder().get(ti))
    
    til_expanded = []
    for ti in til:
        # task instances could be declared as individual named instances or as instance arrays
        if ti.num_task_instances:
            # is a task-instance-array
            for i in range(ti.num_task_instances):
                tic = copy.copy(ti)
                tic.taskname = "{}_{}".format(ti.taskname, i) # TODO: use ti.gen_instance_name list
                til_expanded.append(tic)
        else:
            # is a named task-instance
            til_expanded.append(ti)


    return til_expanded,til

"""
Construct and return a list of all nodes of type nac.task_definition
"""
def glean_task_definition_nodes(T):
    tasks = T.select('task_definition')
    td_list = []
    for task in tasks:
        task.calc_parents()
        task.calc_depth()
        task.calc_position()
        td_list.append(NaASTBuilder().get(task))
    
    for a in td_list:
        a.calc_depth()
        a.calc_index_in_parent()

    return td_list

"""
    returns a tuple (al, bl, cl)
    al:  
    bl:
    cl: 
    If a is None, b is complete
"""
def glean_tasks(T):
    tdefs = glean_task_definition_nodes(T)
    tinstances, tinstances_unexpanded = glean_task_instances(T)
    tdefs_parameterized=collections.OrderedDict()
    tasks=[] # to hold tuples: (reference to instance parameters, tdef)

    for tdef in tdefs:
      if tdef.is_completely_specified():
        tasks.append((None, tdef)) 
      else:
        tdefs_parameterized[tdef.taskname]=tdef

    for ti in tinstances:
      if ti.taskdefname in tdefs_parameterized:
        tasks.append((ti, tdefs_parameterized[ti.taskdefname]))
      else:
        raise CompilationError("Undefined task definition " +ti.taskdefname+ " for instance "+ti.taskname)
    return tasks, tinstances_unexpanded, tdefs

def glean_taskgroups(T):
    tgroups = T.select('task_group')
    tg_dict = collections.OrderedDict()
    for tg in tgroups:
        tg.calc_parents()
        tg.calc_depth()
        tg.calc_position()
        #tg_list.append(NaASTBuilder().get(tg))
        x = NaASTBuilder().get(tg)
        tg_dict[x.taskgroupname] = x
    
    for k,v in tg_dict.items():
        v.calc_depth()
        v.calc_index_in_parent()

    return tg_dict 

"""
Construct a return all hw_kernel declarations
print(T.select('translation_unit  =declaration /msg_object_type_list/')[1].pretty())

"""
def glean_hw_kernel_declarations(T, options):
    hwkdecll = []
    hwkds = T.select('=declaration /hw_kernel/')
    hwkds_ = T.select('translation_unit  =declaration /msg_object_type_list/')
    # if pe is not marked, warn
    if not (len(hwkds) == len(hwkds_)):
        print("\tmissing 'pe' type_specifier on kernel declarations")
        hwkds = hwkds_

    zip4_taskinfo_parameter = []
    # add task_id (physical address on the NoC) as a default first parameter to the hwkdecl
    # as a __reg__
    if not options.no_task_info:
        ts = ['NATaskInfo']
        tn = ['task_info']
        tsz = [1]
        tscs = ['__reg__']    
        zip4_taskinfo_parameter = list(zip(ts, tn, tsz, tscs))


    for hwkd in hwkds:
        pename = hwkd.select1('init_declarator > instance_name > *')
        [tq] = hwkd.select('type_qualifier > *') or [None]
        if tq == '__vhls__':
            tq = '__vivadohls__'
        ts = [d.select('struct_or_union_name > *') for d in hwkd.select('=msg_object_declaration')]
        tn = [d.select('instance_name > *') for d in hwkd.select('=msg_object_declaration')]
        tsz = [d.select('array_size > size > *') for d in hwkd.select('=msg_object_declaration')]
        tscs = [d.select('storage_class_specifier>*') for d in hwkd.select('=msg_object_declaration')]
        ts =   [x[0] for x in ts]
        tn =   [x[0] for x in tn]
        tsz = [eval_num_expr(x[0]) if x else 1 for x in tsz]
        tscs = [x[0] if x else None for x in tscs] # TODO : __fifo__ instead of None
        
        zip4 = zip4_taskinfo_parameter + list(zip(ts, tn, tsz, tscs))
        iface_iodirs = list(map(get_direction_annotation, [e[1] for e in zip4]))

        hwkdecll.append(HWKernelDeclaration(name=pename, tq=tq, ziplist=zip4, iface_iodirs=iface_iodirs))
    
    return hwkdecll

from .amodel import *
from codegen.codegen import *

def get_mako_template_search_paths():
    template_dirs = [
                     './codegen/templates/bsv', 
                     './codegen/templates/connect', 
                     './codegen/templates/sim',
                     './codegen/templates/misc',
                     './codegen/templates/scemi',
                     './codegen/templates/vhls',
                     './codegen/templates/vivado',
                     './codegen/templates/mpimodel'
                    ]
    template_dirs = [resourcePath(d) for d in template_dirs]
    return template_dirs 

def get_default_header_text0():
    s = """ struct NATaskInfo { uint8_t node_id; }; """
    # add in the end to let the user structs have the tag-0...
    return bytes(s, 'utf-8')

def cpp_extract_userdefmacros(nafile):
    cpp_normal_opts = '-P -C -traditional '
    cpp_extract_userdef_macros = cpp_normal_opts + '-nostdinc  -undef -dM -U__STDC_HOSTED__ -U__STDC_VERSION__ -U__STDC_UTF_32__ -U__STDC_UTF_16__ '
    process = subprocess.Popen("cpp "+cpp_extract_userdef_macros+nafile, shell=True, stdout=subprocess.PIPE)
    defs = process.communicate()[0]
    def get_outname():
        # dn/abc.na ==> .abc_defs.h 
        bn = os.path.basename(nafile)
        dn = os.path.dirname(nafile)
        bn = '.' + os.path.splitext(bn)[0]+'_defs.h'
        (dest, name) =  tempfile.mkstemp(dir=dn)
        return dn, bn, dest, name
    
    dirn, basename_defsfile, tmpfh, tmpfn = get_outname()
    hdrguard = basename_defsfile.replace('.','_').upper()
    defs = """
#ifndef {0}
#define {0}
 
{1}
#endif""".format(hdrguard, defs.decode())
    os.write(tmpfh, defs.encode())
    os.close(tmpfh)
    outfile = os.path.join(dirn, basename_defsfile)
    shutil.move(tmpfn, outfile)
    return outfile

def cpp_pass(nafile, sysargs):
    cpp_normal_opts = '-P -C -traditional '
    if sysargs.generate_mpi_model:
        cpp_normal_opts += ' -DMPI_MODEL ' # to enable sections of code for MPI
    #
    # cpp -P -C -traditional file.na | skip_5_comment_headers
    #   - traditional retains empty lines
    #   - cpp-4.8 to cpp-7 all add 5 comment headers
    #
    def skipnotices(ss):
        pat = bytes("*/\n\n", 'utf-8')
        for n in range(0,5):
            k = ss.find(pat)
            ss = ss[k+4:]
        return ss
    def to_hidden_name(filename):
        bn = os.path.basename(filename)
        dn = os.path.dirname(filename)
        bn = '.' + bn
        return os.path.join(dn, bn)
    
    import subprocess
    import tempfile 
    import shutil
    na_defs_file = cpp_extract_userdefmacros(nafile)
    process = subprocess.Popen("cpp "+cpp_normal_opts+nafile, shell=True, stdout=subprocess.PIPE)
    ss = process.communicate()[0]
    ss = skipnotices(ss)

    sheader0 = get_default_header_text0()
    (dest, name) =  tempfile.mkstemp(dir=os.path.dirname(nafile))
    os.write(dest, ss+sheader0)
    os.close(dest)
    nafile = to_hidden_name(nafile)
    shutil.move(name, nafile)


    return nafile, na_defs_file





def onetime_setup_vivado_simlibs(options):
    def simlib_gen(targetdir, simulator):
        script = '''
        compile_simlib -simulator {1} -dir {0}
        #compile_simlib -family zynq -language verilog -library unisim -simulator {1} -dir {0}
        exit
        '''.format(targetdir, simulator)
        f = tempfile.NamedTemporaryFile()
        f.write(script.encode())
        f.flush()
        cmd = 'vivado -nojournal -nolog -mode tcl -source {}'.format(f.name)
        run_command(cmd, 0, 0)
        f.close()
    #
    # simulation environment setup and verification
    #
    if options.simulator in ['xsim', 'iverilog']:
        # nothing to do
        return

    def simlib_directory_looks_okay(stampfile='.cxl.stat'):
        return os.path.isfile( os.path.join(options.simulator_simlib_path, stampfile))

    is_default_path = options.simulator_simlib_path.find('_SIMULATOR') != -1 # replace the default metavar with the actual
    # default path, fix up before use
    if is_default_path:
        options.simulator_simlib_path = os.path.join(os.environ['HOME'], '.config', 'nac', 'simlib_' + options.simulator)
        if simlib_directory_looks_okay():
            return
    
    # user specified path, verify
    if not is_default_path:
        if simlib_directory_looks_okay():
            return 
        else:
            print("\n\tsimlib directory at {} for simulator:{} appears invalid\n".format(options.simulator_simlib_path, options.simulator))

    # do a one time setup 
    trymkdir_p(options.simulator_simlib_path)
    stampfile=os.path.join(options.simulator_simlib_path, '.nac.generated')
    # if previously generated, skip
    if not simlib_directory_looks_okay(stampfile):
        if 'XILINX_VIVADO' not in os.environ:
            msg = """
            to generate one-time vivado simlib directory...
            source /opt/Xilinx/Vivado/2016.4/settings64.sh # or the equivalent 
            and re-run nac
            """
            print(msg)
            sys.exit(1)
        simlib_gen(options.simulator_simlib_path, options.simulator)
        touch(stampfile)

    
        
from optparse import OptionParser
from argparse import ArgumentParser

def runmain(options):
    nafile = options.nafile
    
    onetime_setup_vivado_simlibs(options)
    
    nafile, nadefsfile  = cpp_pass(nafile, options)
    T                   = get_parse_tree(nafile, options.naparse_debug)
    types               = glean_type_declaration_nodes(T)
    hwkernels           = glean_hw_kernel_declarations(T, options)
    taskgroups          = glean_taskgroups(T)
    tasks, tinstances_unexpanded, tdefs_original = glean_tasks(T)
    
    
    AM = amodel(nafile, nadefsfile, toolroot, types, hwkernels, tasks, taskgroups, tinstances_unexpanded, tdefs_original, options)
    AM.setup()
    if options.mode_taskgraphgen:
        try:
            AM.taskgraph_gen() 
        except Exception as e:
            print("warning: exception in tgen: ", e)
            pass
        sys.exit(0)
    AM.prepare_outdir_layout()
    AM.sanitychecks()
    
    CG = codegen(AM, get_mako_template_search_paths())
    CG.hwkernel_wrappers()
    if options.vhlswrap_outdir:
        CG.vhls_hwkernel_wrappers()
    else:
        CG.generate_vivado_scripts()
    
    if options.generate_mpi_model:
        CG.generate_mpi_model()
        sys.exit()
    CG.generate_tasks_file()
    CG.generate_n_files()
    CG.generate_na_files()
    CG.generate_sim_files()
    AM.dump_line_annotations()
    #AM.get_all_communication_arcs()
    #CG.add_gitignores()

def argsanitychecks(sargs):
    assert os.path.isdir(sargs.nocdir), "specified --noc DIR %r does not exist" % sargs.nocdir 
    assert os.path.isfile(sargs.nafile), "nafile %r does not exist" % sargs.nafile 
    if not sargs.runtime_data_list:
        sargs.runtime_data_list = []
    if not sargs.scemi_src_list:
        sargs.scemi_src_list = []
    elif not sargs.scemi:
        sargs.scemi = True


    if sargs.taskmap_json_file:
        assert os.path.isfile(sargs.taskmap_json_file), "specified taskmap file does not exist"




def run():
    from configargparse import ArgParser, ArgumentDefaultsHelpFormatter, ArgumentDefaultsRawHelpFormatter
    from configargparse import SUPPRESS as arg_SUPPRESS
    parser = ArgParser(default_config_files=[])
    parser = ArgParser()
    #parser.formatter_class = ArgumentDefaultsRawHelpFormatter 
    parser.formatter_class = ArgumentDefaultsHelpFormatter
    group1 = parser.add_argument_group("Core Arguments")
    group2 = parser.add_argument_group("Other Arguments")

    group1.add('-c', '--my-config', 
            required=True, help='configuration file [with nac options]',
            is_config_file=True)
    
    group1.add('nafile',  
            help='.na application description file')
    
    group1.add('--noc', '-n', 
            required=False, help="path to either of CONNECT or ForthNoC generated NoC build directory",
            action="store", metavar='NOC_BUILDDIR', dest="nocdir")
    
    group1.add('--outdir', '-odir', 
            required=True, help="path to the work-directory to be generated",
            action="store", metavar='OUTDIR', dest="cgenoutdir") 
  
    group1.add('--mode-taskgraphgen', '-tg', 
            required=False, 
            #help="generates taskgraph in the OUTDIR and quits.",
            help=arg_SUPPRESS,
            action="store_true")
    
    group2.add('--simverbosity', 
            help='simulation time verbosity',
            action='store', choices=['state-entry-exit', 'state-exit', 'to-from-network', 'send-recv-trace'])

    group1.add('--simulator', 
            help='simulator selection (use vcs or xsim when using HLS kernels, and vcs for hw-sw-scemi simulation)',
            action='store', default='xsim', choices=['xsim', 'vcs', 'iverilog'], metavar="SIMULATOR")
    
    group2.add('--simulator-simlib-path', 
            help=' (a one-time step) generates simlibs if not present.',
            action='store', default=os.path.join(os.environ['HOME'], '.config/nac/', 'simlib_SIMULATOR')) 
    #TODO https://stackoverflow.com/questions/20048048/argparse-default-option-based-on-another-option
    
    # deprecated
    group2.add('--vhlswrappers', '-hlswrap', 
            action="store", metavar='VHLS_WRAPPER_OUT_DIR', dest="vhlswrap_outdir", help=arg_SUPPRESS)
    
    group1.add('--vhls-kernels-dir', '-hlskernels', 
            help="directory to both place generated hardware kernel wrappers (C++/Vivado HLS), or to find ready kernels",
            action="store", metavar='VHLS_WRAPPER_OUT_DIR', dest="vhlswrap_outdir")
    
    group1.add('--kernel-specs-file', '-kspecs', 
            help="Kernel specifications. e.g. Duration",
            action="store")

    
    group2.add('--build-dir-vhls', '-hlsbuilddir', 
            action="store", metavar='BUILD_DIR_HLS', dest="build_dir_vhls", 
            help=arg_SUPPRESS)
    
    group2.add('--bsvwrappers', '-bsvwrap', action="store", metavar='BSV_WRAPPER_OUT_DIR', dest="kernelwrapper_outdir", 
            help="directory to place generated BSV kernel wrappers")
    
    group1.add('--taskmap', '-map',
            required=False, help="task map .json file (corresponding to the NOC chosen)",
            action="store", dest="taskmap_json_file")
    
    group2.add('--buffersizingspecs', 
            required=False, 
            help=arg_SUPPRESS,
            action="store") 
    
    group2.add('--buffered-sr-ports', 
            required=False, help="buffer the send-recv ports exposed (TODO use --buffersizingspecs later of this)",
            action="store_true", default=False)
    
    group2.add('--random-taskmap', 
#             help='use a random task mapping (different with each run)',
            help=arg_SUPPRESS,
            dest='taskmap_use_random', action='store_true') 
    
    group2.add('--scemi', 
            help='generate SCEMI stuff (True if scemi_src_list specified)',
            action='store_true') 
    
    group2.add('--no-task-info', 
            help='do no add an implicit task_info parameters to kernels declarations',
            action='store_true')
    
    group2.add('--hwkernels-regen', 
             help=arg_SUPPRESS,
             dest='regenerate_kernels', action='store_true')
    
    # deprecated
    group1.add('--runtime-src-list', 
            required=False, help=arg_SUPPRESS,
            dest='scemi_src_list',
            action="append", metavar='RT_SRC') 
    
    group1.add('--scemi-src-list', 
            required=False, help="scemi src list; use cfg file ",
            action="append", default=[], metavar='RT_SRC') 
    
    group1.add('--runtime-data-list',
            required=False, help="runtime data list; use cfg file",
            action="append", metavar='RT_DATA') 
    
    group2.add('--fnoc-supports-multicast', 
            help='specify if the FNOC supports broadcast/multicast feature',
            action='store_true', default=False) 
    
    group1.add('--mode-generate-mpi-model', '-mpi',
            help='generate MPI model for the design entry (with HLS kernels only)',
            action='store_true', dest='generate_mpi_model', default=False) 
    
    group1.add('--mpi-src-list', 
            required=False, help="uses the 'host node' source files provided; format nahost_<taskname>.cpp",
            action="append", default=[], metavar='MPI_SRC') 

    group2.add('--dbgna', '-dbg',
            #help='debug na parse stage (internal)',
            help=arg_SUPPRESS,
            action='store_true', dest='naparse_debug', default=False)
    
    group2.add('--new-tofrom-network', '-ntfnw',
            help='Use the newer version of to-from network',
            action='store_true', default=False)
    
    group2.add('--enable-lateral-bulk-io', '-bulkio',
            help='Export bulk IO ports to external-tasks',
            action='store_true', default=True)

    group2.add('--either-or-lateral-io', default=True) # qfix
 
    group2.add('--event-trace', '-evts',
            help='A markers to record time spent at various places',
            action='store_true', default=False)
    
    
    sargs = parser.parse_args()
 
    #
    # Adjustments where necessary
    #
    if not sargs.vhlswrap_outdir:
        sargs.vhlswrap_outdir = 't_hlssources'
    
    if not sargs.build_dir_vhls:
        sargs.build_dir_vhls = 'build_' + sargs.vhlswrap_outdir 
    #----------------------------------------------------------------------------------------------

    print(parser.format_values())
    
    # TODO print cfg to a file in ODIR/ispecs
    # serializedcfg_str = parser._config_file_parser.serialize(sargs.__dict__)
    
    argsanitychecks(sargs)
    
    runmain(sargs)

#--------------------------------------------------------------------------------------------------
