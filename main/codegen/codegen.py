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
import collections

import tempfile

from main.na_utils import *

def write_to_dir_as(outdir, fpath, source, silent=False):
    outputpath = os.path.join(outdir, fpath)
    if os.path.exists(outputpath) and file_contains_exactly_these_bytes(bytes(source, 'UTF-8'), outputpath):
        print('nochange, untouched\t', outputpath)
        return outputpath 
    
    (dest, name) =  tempfile.mkstemp(dir=os.path.dirname(outputpath))
    os.write(dest, bytes(source, 'UTF-8'))
    os.close(dest)
    moveFile(name, outputpath)
    if not silent:
        print ('> generated\t\t',outputpath)
    return outputpath 


"""

"""
class codegen(object):
    def __init__(self, amodel, template_dir_list): 
        self._am = amodel
        self._tlookup = TemplateLookup(directories=template_dir_list)
        self.hwkernelmap = collections.OrderedDict()
        self.vhls_build_dir=os.path.abspath(self._am.args.build_dir_vhls)
        self.gitignore_ = []
        self.top_function_list = []
        self._ispec_dir = os.path.join(self._am.outdir, 'ispecs')
        
        # Copy the na and config files to ispecs/ 
        copyFile(self._am.args.my_config, self._ispec_dir) 
        copyFile(self._am.nafile_path, self._ispec_dir) 
        copyFile(self._am.nafile_postcpp, self._ispec_dir) 
        copyFile(self._am.namacros_file, self._ispec_dir, dont_if_identical=True) # to trigger HLS make targets only when necessary

    
    def gitignore(self, p):
        gi = self.gitignore_
        if not gi: # init
            gi.append(self._am.args.build_dir_vhls)
            gi.append(self._am.outdir)
        self.gitignore_.append(p)
    
    def add_gitignores(self):
        od = os.path.dirname(self._am.nafile_path)
        if not os.path.exists(os.path.join(od, '.gitignore')):
            ss = '\n'.join(self.gitignore_)
            write_to_dir_as(od, '.gitignore', ss, True)

    """ TODO split tasks into their own files """
    def generate_tasks_file(self):
        try:
            hwkernels = self.get_active_kernels()
            T = self._tlookup.get_template('Tasks.mako.bsv')
            rend = T.render(_am=self._am,_hwkernels=hwkernels)
            write_to_dir_as(self._am.outdir, 'src/Tasks.bsv', rend)
        except:
            print(exceptions.text_error_template().render())


    def find_pe_in_lib(self, kernel_name, is_vhls=False):
        Kn = self._am.hwkernelname2modname(kernel_name)
        Kfn = Kn + '.bsv'
        p = None
        if is_vhls:
            p = os.path.join(self._am.hls_bviwrappers_outdir, Kfn)
        else:
            p = os.path.join(self._am.pelib_dir, Kfn)
        return (os.path.exists(p), p, Kn)

         
    def is_file_marked_NO_AUTOREPLACE(self, basedir, file):
        p = os.path.join(basedir, file)
        if os.path.exists(p):
            line0=open(p).readline().rstrip()
            if "//NO_AUTOREPLACE" in line0:
                return True
        return False
    
    def find_hlswrapper_in_outdir(self, cppfile):
        return self.is_file_marked_NO_AUTOREPLACE(self._am.vhlswrappergen_dir, cppfile)

    
    def scan_for_hwkernels(self):
        hwkmap = dict()
        for tmodel in self._am.tmodels:
            for kc in tmodel.kernelcalls:
                (found, p, modname) = self.find_pe_in_lib(kc.kernel_name)
                if found:
                    hwkmap[kc.kernel_name] = (p, modname)
        return hwkmap
    
    def generate_vivado_scripts(self):
        # vivado project generation script for simulation
        T = self._tlookup.get_template('create_project.mako.tcl')
        outdir_abspath = os.path.abspath(self._am.outdir)
        target_dir_abspath = os.path.abspath(self._am.out_simdir)
        if self._am.psn.is_fnoc():
            final_fileset_dir_path = os.path.join(target_dir_abspath, "stage_sim")
        else:
            final_fileset_dir_path = os.path.join(target_dir_abspath, "stage_sim")
        hls_top_instance_namepairs = None
        if self.top_function_list:
            hls_top_instance_namepairs = [(x, x+"_0") for x in self.top_function_list]
        sim_behav_vivado_renderparameters = ("project_1", 
                outdir_abspath,
                target_dir_abspath,
                final_fileset_dir_path,
                os.path.basename(self.vhls_build_dir),
                hls_top_instance_namepairs
                )

        rend = T.render(sim_behav_vivado_renderparameters=sim_behav_vivado_renderparameters,_am=self._am)
        write_to_dir_as(self._am.out_scriptdir, 'create_project.tcl', rend)
        
        # then, open and_ run this synthesis script
        T = self._tlookup.get_template('open_and_synthesize.mako.tcl')
        params = sim_behav_vivado_renderparameters
        rend = T.render(params=params,_am=self._am)
        write_to_dir_as(self._am.out_scriptdir, 'open_and_synthesize.tcl', rend)


    def run_m4_pass(self, srcfile, outdir, outfilename):
        s_mpicc = "m4 -P "+self._am.outdir+"/libna/na_hostmacros.m4 {0} > {1}/{2}\n".format(srcfile, outdir, outfilename)
        run_command(s_mpicc, 0, 0)



    def generate_mpi_model(self):
        m4dir = os.path.join(self._am.toolroot, "libs/libna/m4_macros")
        copyFile(os.path.join(m4dir, 'na_hostmacros.m4'), os.path.join(self._am.outdir, 'libna/')) 

        libna_dir = os.path.join(self._am.toolroot, "libs/libna/")
        copyFile(os.path.join(libna_dir, 'myfifo.h'), os.path.join(self._am.outdir, 'libna/')) 
        def localt2f(template, outfile, taskname=None, checkifreplacable=False):
            if checkifreplacable:
                if self.is_file_marked_NO_AUTOREPLACE(self._am.out_swmodeldir, outfile):
                    return # nothing to do

            T = self._tlookup.get_template(template)
            try:
                rend = T.render(_am=self._am, _tname=taskname)
            except:
                print(exceptions.text_error_template().render())
            rend = pastyle_cpp(rend)    
            f = write_to_dir_as(self._am.out_swmodeldir, outfile, rend)
            return f


        localt2f('mpimodel_main.mako.cpp', 'mpimodel_main.cpp')
        localt2f('mpimodel.mako.h', 'mpimodel.h')
        
        # Copy over files from self._am.args.mpi_src_list to self._am.out_swmodeldir
        # Generate templates for those not listed in it
        for _,tname,_ in self._am.get_tasks_marked_for_exposing_flit_SR_ports():
            outbasename = 'natask_'+tname+'.cpp' 
            ll = [os.path.basename(f) for f in self._am.args.mpi_src_list if os.path.exists(f)]
            if outbasename in ll:
                srcf = self._am.args.mpi_src_list[ll.index(outbasename)]
                copyFile(srcf, self._am.out_swmodeldir)
            else:
                of = localt2f('mpi_hostnode.mako.cpp', outbasename, tname, True)
                print('INFO: generated a template MPI node for task:{} at {}'.format(tname, of))
        
        
        # MPI makefile
        T = self._tlookup.get_template('MPIMakefile.mako')
        try:
            hls_func_list = [f[:-4] for f in self.get_hls_cpp_file_names()]
            rend = T.render(_am=self._am, hls_func_list=hls_func_list)
        except:
            print(exceptions.text_error_template().render())
        write_to_dir_as(self._am.out_swmodeldir, 'Makefile', rend)

        self.vhls_rewrap_for_fifos();
    
    def get_hls_cpp_file_names(self):
        cpp_files = []
        for d in self._am.hwkdecls:
            if not (d.tq == '__vivadohls__'):
                continue
            modname = d.name
            cpp_files.extend([modname+'.cpp'])
        return cpp_files

    def vhls_rewrap_for_fifos(self):
        T = self._tlookup.get_template('VHLS_rewrap_for_FIFOs.mako.cpp')
        cpp_files = [] # TODO replace with get_hls_cpp_file_names
        outrend = ''
        for d in self._am.hwkdecls:
            if not (d.tq == '__vivadohls__'):
                continue
            modname = d.name
            cpp_files.extend([modname+'.cpp'])
            try:
                rend = T.render(_am=self._am,modname=modname, pedecl=d)
            except:
                print(exceptions.text_error_template().render())
            outrend+=rend

        outrend = pastyle_cpp(outrend)    
        write_to_dir_as(self._am.out_swmodeldir, 'rewrapped_hwkernels.cpp', outrend)
        pass 
    
    def vhls_hwkernel_wrappers(self):
        # header
        T = self._tlookup.get_template('VHLS_NATYPES.mako.h')
        try:
            rend = T.render(_am=self._am)
        except:
            print(exceptions.text_error_template().render())
        write_to_dir_as(self._am.vhlswrappergen_dir, 'vhls_natypes.h', rend)
        self.gitignore(os.path.join(self._am.vhlswrappergen_dir, 'vhls_natypes.h'))

        # Create or touch if already exists: mydefines.h 
#         touch(os.path.join(self._am.vhlswrappergen_dir, "mydefines.h"))
        copyFile(self._am.namacros_file, self._ispec_dir, dont_if_identical=True) # to trigger HLS make targets only when necessary
        mydefsfile = os.path.join(self._am.vhlswrappergen_dir, "mydefines.h")
        if not os.path.exists(mydefsfile):
            ss = '#include "{}"'.format(self._am.namacros_file)
            with open(mydefsfile, "w") as fh:
                fh.write(ss)
        else:
            #print("NOTE: prepare to overwrite mydefines.h in the future; consider deleting it now")
            #touch(mydefsfile)
            pass

        copyFile(self._am.namacros_file, self._am.vhlswrappergen_dir) 
        copyFile(os.path.join(self._am.vhlswrappergen_dir, 'vhls_natypes.h'), 
                os.path.join(self._ispec_dir, 'vhls_natypes.h'))
        copyFile(os.path.join(self._am.vhlswrappergen_dir, 'mydefines.h'), self._ispec_dir)


        # function wrappers
        T = self._tlookup.get_template('VHLSFWrappers.mako.cpp')
        cpp_files = [] # TODO replace with get_hls_cpp_file_names
        for d in self._am.hwkdecls:
            if not (d.tq == '__vivadohls__'):
                continue
            modname = d.name
            cpp_files.extend([modname+'.cpp'])
            no_autoreplace=self.find_hlswrapper_in_outdir(d.name+'.cpp')
            if no_autoreplace:
                continue
            try:
                rend = T.render(_am=self._am,modname=modname, pedecl=d)
            except:
                print(exceptions.text_error_template().render())

            write_to_dir_as(self._am.vhlswrappergen_dir, modname+'.cpp', rend)
        if cpp_files:
            s = "\n".join(["#if defined(INCLUDE_"+os.path.splitext(f)[0]+")\n#include \""+f+"\"\n#endif\n" for f in cpp_files])
            write_to_dir_as(self._am.vhlswrappergen_dir, 'combined.cpp', s)
            self.gitignore(os.path.join(self._am.vhlswrappergen_dir, 'combined.cpp'))


        #  vhls script
        # 
        T = self._tlookup.get_template('VHLS_SCRIPT.mako.tcl')
        add_files = ["combined.cpp","mydefines.h","vhls_natypes.h"]
        abspaths = [os.path.join(os.path.abspath(self._am.vhlswrappergen_dir), f) for f in add_files]
        top_function_list = [f[:-4] for f in cpp_files]
        self.top_function_list = top_function_list
        vhls_script_renderparameters = (abspaths, top_function_list, os.path.basename(self.vhls_build_dir))
        #rend = T.render(src_filelist_abspaths=abspaths,top_function_list=top_function_list)
        rend = T.render(vhls_script_renderparameters=vhls_script_renderparameters,_am=self._am)
        write_to_dir_as(self._am.vhlswrappergen_dir, 'vhls_script.tcl', rend)
        self.gitignore(os.path.join(self._am.vhlswrappergen_dir, 'vhls_script.tcl'))

        self.generate_vivado_scripts()


    def hwkernel_wrappers(self):
        #hwkmap = self.scan_for_hwkernels()
        #pdb.set_trace()

        T = self._tlookup.get_template('KernelWrapper.mako.bsv')
        for d in self._am.hwkdecls:

            (found_pe, p, modname) = self.find_pe_in_lib(d.name, d.tq=='__vivadohls__')
            if self._am.args.regenerate_kernels:
                # bkp, regen
                if found_pe:
                    moveFile(p, p+'.bkp')
                found_pe = False

            if found_pe and d.tq != '__vivadohls__': # update bvi/hls if necessary
                continue
            try:
                rend = T.render(_am=self._am,modname=modname, pedecl=d)
            except:
                print(exceptions.text_error_template().render())

            if '__vivadohls__' == d.tq:
                write_to_dir_as(self._am.hls_bviwrappers_outdir, modname+'.bsv', rend)
            else:
                write_to_dir_as(self._am.pelib_dir, modname+'.bsv', rend)
        hwkmap = self.scan_for_hwkernels()
        self.hwkernelmap = hwkmap

    def get_active_kernels(self):
        aml = []
        for tm in self._am.tmodels:
            l = tm.get_hwkernel_modnames()
            l = [a[0] for a in l]
            aml.extend(l)
        aml = collections.OrderedDict.fromkeys(aml).keys()
        return aml


    def generate_simheader_scemi(self):
        try:
            T = self._tlookup.get_template('scemi_na_util.mako.h')
            rend = T.render(_am=self._am)
            rend = pastyle_cpp(rend)    
            write_to_dir_as(self._am.outdir, 'tbscemi/scemi_na_util.h', rend, silent=False)
        except:
            print(exceptions.text_error_template().render())

    
    def generate_vhls_script_tcl(self): # TODO deprecate
        T = self._tlookup.get_template('VHLS_SCRIPT.mako.tcl')
        add_files = ["combined.cpp","mydefines.h","vhls_natypes.h"]
        abspaths = [os.path.join(os.path.abspath(self._am.vhlswrappergen_dir), f) for f in add_files]
        cpp_files = self.get_hls_cpp_file_names()
        top_function_list = [f[:-4] for f in cpp_files]
        self.top_function_list = top_function_list
        vhls_script_renderparameters = (abspaths, top_function_list, os.path.basename(self.vhls_build_dir))
        #rend = T.render(src_filelist_abspaths=abspaths,top_function_list=top_function_list)
        rend = T.render(vhls_script_renderparameters=vhls_script_renderparameters,_am=self._am)
        write_to_dir_as(self._am.out_scriptdir, 'vhls_script.tcl', rend)
        self.gitignore(os.path.join(self._am.vhlswrappergen_dir, 'vhls_script.tcl'))

    def _generate_Makefiles(self):
        def get_vhls_renderitems():
            add_files = ["mydefines.h","vhls_natypes.h", self._am.namacros_file]
            abspaths = [os.path.join(os.path.abspath(self._am.vhlswrappergen_dir), f) for f in add_files]
            cpp_files = self.get_hls_cpp_file_names()
            top_function_list = [f[:-4] for f in cpp_files]
            self.top_function_list = top_function_list
            vhls_script_renderparameters = (abspaths, top_function_list, os.path.basename(self.vhls_build_dir))
            return vhls_script_renderparameters

        # sim/ folder
        T = self._tlookup.get_template('Makefile.mako')
        rend = T.render(_am=self._am, vhls_render_params=get_vhls_renderitems())
        write_to_dir_as(self._am.out_simdir, 'Makefile', rend, silent=True)
        self.generate_vhls_script_tcl()


            

    def _scemi_src_arrangements(self):
        outdir = os.path.join(self._am.outdir, 'tbscemi')
        def localt2f(template, outfile, taskname=None, checkifreplacable=False):
            if checkifreplacable:
                if self.is_file_marked_NO_AUTOREPLACE(outdir, outfile):
                    return 'exists', os.path.join(outdir, outfile)# nothing to do

            T = self._tlookup.get_template(template)
            try:
                rend = T.render(_am=self._am, _tname=taskname)
            except:
                print(exceptions.text_error_template().render())
            rend = pastyle_cpp(rend)    
            f = write_to_dir_as(outdir, outfile, rend)
            return 'generated', f
        lsrtasks = list(filter(lambda x: x[2]=='scemi', self._am.get_tasks_marked_for_exposing_flit_SR_ports()))
        lsrc = [os.path.basename(f) for f in self._am.args.scemi_src_list if os.path.exists(f)]
        if len(lsrc) == len(lsrtasks):
            for f in lsrc:
                copyFile(f, outdir)
            return # nothing more to do
        # Generate templates for those not listed in src_list # TODO generating now for all anyway
        for _,tname,marker in self._am.get_tasks_marked_for_exposing_flit_SR_ports():
            if marker == 'scemi':
                outbasename = 'scemi_'+tname+'.skeleton.cpp' 
                status, of = localt2f('scemi_hostnode.mako.cpp', outbasename, tname, True)
                print('INFO: {}, a template SCEMI node for task:{} at {}'.format(status, tname, of))
            else:
                print("INFO: {} marked {} (not treating as scemi)", tname, marker)


    def generate_sim_files(self):
        def outpath(filename, subdir='.'):
            return os.path.join(os.path.join(self._am.outdir, subdir), filename)
        
        m4dir = os.path.join(self._am.toolroot, "libs/libna/m4_macros")
        copyFile(os.path.join(m4dir, 'na_hostmacros.m4'), os.path.join(self._am.outdir, 'libna/')) 
        try:
            for f in self._am.args.runtime_data_list:
                copyFile(f, outpath(os.path.basename(f), 'data'))
#---
            if self._am.args.scemi:
                self._scemi_src_arrangements()
#---
            ## misc files
            libscripts_dir = os.path.join(self._am.toolroot, "scripts/")
            copyFile(os.path.join(libscripts_dir, 'postsim_query_tracedb.py'), os.path.join(self._am.out_simdir)) 
            copyFile(os.path.join(libscripts_dir, 'psn_util.py'), os.path.join(self._am.out_simdir)) 
            copyFile(os.path.join(libscripts_dir, 'postsim_make_tracedb.py'), os.path.join(self._am.out_simdir)) 
            
            ###
            T = self._tlookup.get_template('tb.v.mako')
            rend = T.render()
            write_to_dir_as(self._am.outdir, 'tb/tb.v', rend, silent=True)
            self._generate_Makefiles()
            
            sim_templates_dir = os.path.join(os.path.dirname(__file__), 'templates/sim')
            copyFile(os.path.join(sim_templates_dir, 'run_icarus.sh'), self._am.out_simdir) 

            scemi_dir = os.path.join(os.path.dirname(__file__), 'templates/scemi')
            libna_dir = os.path.join(self._am.toolroot, "libs/libna/")
            if self._am.args.scemi:
                self.generate_simheader_scemi()
                copyFile(os.path.join(scemi_dir, 'Bridge.bsv'), os.path.join(self._am.outdir, 'scemi/'), dont_if_identical=True) 
                T = self._tlookup.get_template('SceMiLayer.bsv')
                rend = T.render(scemi_port_id=self._am.get_lone_scemi_port_id(), _am=self._am)
                write_to_dir_as(os.path.join(self._am.outdir, 'scemi'), 'SceMiLayer.bsv', rend, silent=True)

                copyFile(os.path.join(scemi_dir, 'main.v'), os.path.join(self._am.outdir, 'scemi/'), dont_if_identical=True) 
                copyFile(os.path.join(scemi_dir, 'support_modules_to_copy.list'), os.path.join(self._am.outdir, 'scemi/')) 
                copyFile(os.path.join(libna_dir, 'nascemi.h'), os.path.join(self._am.outdir, 'libna/')) 
                copyFile(os.path.join(libna_dir, 'nascemi.cpp'), os.path.join(self._am.outdir, 'libna/')) 
                copyFile(os.path.join(libna_dir, 'myfifo.h'), os.path.join(self._am.outdir, 'libna/')) 
        except:
            print(exceptions.text_error_template().render())
                    

    def generate_n_files(self):
        try:
            # NI Bridge: common for CONNECT Credit or Peek type NoCs and ForthNoC
            T = self._tlookup.get_template('CnctBridge.mako.bsv')
            rend = T.render(_am=self._am)
            write_to_dir_as(self._am.outdir, 'src/CnctBridge.bsv', rend)
            
            # Interface skeleton BSV for CONNECT Credit or Peek type NoCs and ForthNoC
            if self._am.psn.is_connect_credit():
                T = self._tlookup.get_template('Network.mako.bsv')
                rend = T.render(_am=self._am)
                write_to_dir_as(self._am.outdir, 'src/Network.bsv', rend)
            else:
                T = self._tlookup.get_template('NetworkSimple.mako.bsv')
                rend = T.render(_am=self._am)
                write_to_dir_as(self._am.outdir, 'src/NetworkSimple.bsv', rend)

            T = self._tlookup.get_template('NTypes.mako.bsv')
            rend = T.render(_am=self._am)
            write_to_dir_as(self._am.outdir, 'src/NTypes.bsv', rend)
        except:
            print(exceptions.text_error_template().render())
    
    def generate_na_files(self):
        try:
            T = self._tlookup.get_template('Top.mako.bsv')
            if self._am.task_partition_map:
                for partname, part_tmap in self._am.task_partition_map.items():
                    rend = T.render(_am=self._am, _partname=partname)
                    write_to_dir_as(self._am.outdir, 'src/Top_'+partname+'.bsv', rend)
            else:
                rend = T.render(_am=self._am)
                write_to_dir_as(self._am.outdir, 'src/Top.bsv', rend)

            if self._am.task_partition_map: # generate a top over mfpga parts for simulation
                T = self._tlookup.get_template('MFpgaTop.mako.bsv')
                rend = T.render(_am=self._am)
                write_to_dir_as(self._am.outdir, 'src/MFpgaTop.bsv', rend)
 
            
            T = self._tlookup.get_template('NATypes.mako.bsv')
            rend = T.render(_am=self._am)
            write_to_dir_as(self._am.outdir, 'src/NATypes.bsv', rend)

            T = self._tlookup.get_template('TbC.mako.bsv')
            rend = T.render(_am=self._am)
            write_to_dir_as(self._am.outdir, 'src/Tb.bsv', rend)
        except:
            print(exceptions.text_error_template().render())
