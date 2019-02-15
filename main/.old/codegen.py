#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 2016 vby
#############################vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""

"""

import sys
import os, errno
import pdb

from mako.template import Template
from mako.lookup import TemplateLookup
from mako.runtime import Context
from mako import exceptions

import tempfile
import os
import shutil


def write_to_dir_as(outdir, fpath, source, silent=False):
    outputpath = os.path.join(outdir, fpath)
    (dest, name) = \
        tempfile.mkstemp(
            dir=os.path.dirname(outputpath)
        )
    os.write(dest, bytes(source, 'UTF-8'))
    os.close(dest)
    shutil.move(name, outputpath)
    if not silent:
        print ('generated ',outputpath)

def copyFile(src, dest):
    try:
        shutil.copy(src, dest)
    # eg. src and dest are the same file
    except shutil.Error as e:
        print('Error: %s' % e)
    # eg. source or destination doesn't exist
    except IOError as e:
        print('Error: %s' % e.strerror)

class BSVCodeGen(object):
    def __init__(self, omodel, template_dir_list): 
        """
        self._om
        """
        self._om = omodel
        self._tlookup = TemplateLookup(directories=template_dir_list)

    def tasks_file(self):
        try:
            T = self._tlookup.get_template('Tasks.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.cgoutdir, 'src/Tasks.bsv', rend)
        except:
            print(exceptions.text_error_template().render())

    def pewrappers_perdecls(self):
        T = self._tlookup.get_template('KernelWrapperBeta.mako.bsv')
        
        for pd in self._om.pe_decls:
            (found_pe, p, modname) = self._om.find_pe_in_lib(pd.name)
            # convert to vivado portnames
            if self._om.args.pewrappers_regen:
                # bkp, regen
                if found_pe:
                    shutil.move(p, p+'.bkp')
                found_pe = False

            if found_pe:
                continue
            try:
                rend = T.render(
                        modname=modname,
                        iargs=pd.iargs(),
                        oargs=pd.oargs(),
                        v_params=pd.v_params,
                        qualifiers=pd.qualifiers,
                        om_=self._om,
                        pd_=pd,
                        stateregs=pd.stateregs(),
                        ziplist=pd.ziplist
                        )
            except:
                print(exceptions.text_error_template().render())

            write_to_dir_as(self._om.pelib_dir, modname+'.bsv', rend)


#     def pewrappers(self):
#         T = self._tlookup.get_template('PEWrapper.mako.bsv')
#                 
#         for tm in self._om.tm_list:
#             kspecs = {}
#             for (modname, iargs, oargs, found_pe) in tm.kernel_specs_list():
#                 if found_pe:
#                     continue
#                 if modname not in kspecs:
#                     kspecs[modname] = (iargs, oargs)
#                 for modname, (iargs, oargs) in kspecs.items():
#                     iargs = [(a.var[0].lower()+a.var[1:], tm.get_typename_for_instance(a.var)) for a in iargs]
#                     oargs = [(a.var[0].lower()+a.var[1:], tm.get_typename_for_instance(a.var)) for a in oargs]
#                     stateregs = [a for a in iargs if tm.instance_has_attrib_state(a[0])] 
#                     iargs = [a for a in iargs if not tm.instance_has_attrib_state(a[0])]
#                     #oargs = [a for a in oargs if not tm.instance_has_attrib_state(a[0])] # assume state_attrib appear as inputs (no &)
# 
#                     rend = T.render(modname=modname,iargs=iargs,oargs=oargs,stateregs=stateregs)
#                     write_to_dir_as(self._om.pelib_dir, modname+'.bsv', rend)
                    

    def connect_files(self):
        try:
            T = self._tlookup.get_template('Top.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.cgoutdir, 'src/Top.bsv', rend)
 
            T = self._tlookup.get_template('CnctBridge.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.cgoutdir, 'src/CnctBridge.bsv', rend)
            
            T = self._tlookup.get_template('NATypes.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.cgoutdir, 'src/NATypes.bsv', rend)

            T = self._tlookup.get_template('Tb.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.cgoutdir, 'src/Tb.bsv', rend)
            pdb.set_trace()   
            T = self._tlookup.get_template('KernelLib.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.pelib_dir, 'KernelLib.bsv', rend)
        except:
            print(exceptions.text_error_template().render())
            

        
        if self._om.noc_uses_credit_based_flowcontrol():
            T = self._tlookup.get_template('Network.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.cgoutdir, 'src/Network.bsv', rend)
        else:
            T = self._tlookup.get_template('NetworkSimple.mako.bsv')
            rend = T.render(om=self._om)
            write_to_dir_as(self._om.cgoutdir, 'src/NetworkSimple.bsv', rend)

        ## misc files
        T = self._tlookup.get_template('tb.v.mako')
        rend = T.render()
        write_to_dir_as(self._om.cgoutdir, 'tb/tb.v', rend, silent=True)
        T = self._tlookup.get_template('Makefile.mako')
        rend = T.render()
        write_to_dir_as(self._om.cgoutdir, 'sim/Makefile', rend, silent=True)

        ## MiscLib
        mlib_dir = os.path.join(os.path.dirname(__file__), 'codegen/templates/MiscLib/')
        copyFile(os.path.join(mlib_dir, 'FPDef.bsv'), os.path.join(self._om.cgoutdir, 'src/FPDef.bsv')) 
        copyFile(os.path.join(mlib_dir, 'FPUWrap.bsv'), os.path.join(self._om.cgoutdir, 'src/FPUWrap.bsv')) 
        copyFile(os.path.join(mlib_dir, 'FPUModel.bsv'), os.path.join(self._om.cgoutdir, 'src/FPUModel.bsv')) 



