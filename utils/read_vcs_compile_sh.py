#! /usr/bin/env python
# -*- coding: utf-8 -*-
############################ vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""
Usage: cd 1_out/sim/ 
       read_vcs_compile_sh.py vcsb out_directory_hdl_files
"""
import os,sys
import shutil

vcsb_path       = os.path.realpath(sys.argv[1])
out_directory   = sys.argv[2]

compile_sh = os.path.join(vcsb_path, 'compile.sh')
with open(compile_sh, 'r') as fh:
    lines = filter(lambda x: x.find('$origin_dir')>=0 , fh)
    lines = [l[l.find('$origin_dir')+12:-4] for l in lines[1:]] # skip first entry
    lines = [os.path.abspath(os.path.join(vcsb_path, l)) for l in lines]
    lines = filter(lambda x:os.path.exists(x), lines)
    if not os.path.isdir(out_directory):
        assert not os.path.isfile(out_directory), "%s exists as a file" % out_directory
        os.mkdir(out_directory)
    for f in lines:
        shutil.copy(f, out_directory)
