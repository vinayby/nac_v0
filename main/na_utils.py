#! /usr/bin/env python3
# -*- coding: utf-8 -*-
""" [2018] vbyk
"""
################## vim:fenc=utf-8 tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import os, errno
import inspect
import pdb

import hashlib
import shutil

def get_file_contents_as_bytes(file):
    with file:
        return file.read()
"""
    Use: 
        - To avoid updating/`touch'ing a generated file if its contents were not going to change
        - (Helping Makefiles, avoid triggering rebuilds (esp. BSV source))
        
"""
def file_contains_exactly_these_bytes(inbytes, thefile):
    a = hashlib.sha256(get_file_contents_as_bytes(open(thefile, 'rb'))).hexdigest()
    b = hashlib.sha256(inbytes).hexdigest()
    return a == b

def files_are_identical(f1, f2):
    a = hashlib.sha256(get_file_contents_as_bytes(open(f1, 'rb'))).hexdigest()
    b = hashlib.sha256(get_file_contents_as_bytes(open(f2, 'rb'))).hexdigest()
    return a == b

def put_in_python_sys_path(idir):
    if idir not in sys.path:
        sys.path.insert(0, idir)


"""
    prettyformat generated c++ code (e.g. MPI, HLS kernel wrappers)
"""
def pastyle_cpp(to_render):
    try:
        import pyastyle 
        rend = pyastyle.format(
                to_render, 
                '--delete-empty-lines      \
                --keep-one-line-blocks     \
                --keep-one-line-statements \
                --max-code-length=120      \
                --break-after-logical      \
                --style=allman ')
        return rend
    except ImportError:
        print("pip3 install pyastyle\n (Emitting without formatting) ")
        pass

def eval_num_expr(exprstring):
    """ eval is a python built-in """
    return int(eval(str(exprstring))) # str() even if int's are passed

def moveFile(src, dest):
    copyFile(src, dest, move_=True)

"""
    Does: 
        - copy/move src-file to dest-dir/src-file or dest-file
        - if asked for dont_if_identical
            do not touch the target file
    returns: True if (asked for dont_if_identical) AND (they weren't)
"""
def copyFile(src, dest, move_=False, dont_if_identical=False):
    try:
        if dont_if_identical:
            targetfile = dest
            if os.path.isdir(dest):
                targetfile = os.path.join(dest,os.path.basename(src))
            if not os.path.exists(targetfile):
                if move_:
                    shutil.move(src, dest)
                else:
                    shutil.copy(src, dest)

            if os.path.exists(targetfile) and files_are_identical(src, targetfile):
                # not touching it then
                return
            else:
                if move_:
                    shutil.move(src, dest)
                else:
                    shutil.copy(src, dest)
                return True

        if move_:
            shutil.move(src, dest)
        else:
            shutil.copy(src, dest)
    # eg. src and dest are the same file
    except shutil.Error as e:
        print('Error1: %s' % e)
    # eg. source or destination doesn't exist
    except IOError as e:
        print(src,dest)
        print('Error2: %s' % e.strerror)

"""Runs a shell command. 

    Args:
        cmd (string) : 
        exit_on_error (Bool) :          
        returnout (Bool) : 

    Returns:
        The output of the `cmd' if returnout is True
"""
def run_command(cmd, exit_on_error, returnout=0):
    import subprocess
    def checkstatus():
        if process.returncode != 0:
            print(out, err)
            if exit_on_error:
                sys.exit(2)

    if returnout:
        process = subprocess.Popen([cmd], shell=True, stderr=subprocess.STDOUT, stdout=subprocess.PIPE)
        out, err = process.communicate()
        checkstatus()
        return out.decode()
    else:
        process = subprocess.Popen([cmd], shell=True)
        out, err = process.communicate()
        checkstatus()

""" `mkdir -p` """
def trymkdir_p(path):
    # for >3.2
    os.makedirs(path, exist_ok=True)
    return
    
    try:
        os.makedirs(path)
    except OSError as e:
        if e.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

""" Some unnecessary contraption around versions of makedirs """
def trymkdir(dirname):
    trymkdir_p(dirname)

""" Update the timestamp of a file """
def touch(fname, times=None):
    with open(fname, 'a'):
        os.utime(fname, times)


""" Creates a symlink 
    (Or create a physical deep-copy when executing in the `frozen'/pyinstaller-bundle mode)

    The target, if exists, is removed and recreated anyway to avoid working with stale files

    Args: 
        file1: file or directory
        file2: a file-path, treated as a symlink or 
"""
def force_symlink(file1, file2):
    if getattr(sys, 'frozen', False):
        import shutil
        if os.path.exists(file2):
            if os.path.islink(file2):
                os.remove(file2) # rmtree cannot remove a symlink
            else:
                shutil.rmtree(file2)
        shutil.copytree(file1, file2)
        return 
    try:
        os.symlink(file1, file2)
    except OSError as e:
        if e.errno == errno.EEXIST:
            os.remove(file2)
            os.symlink(file1, file2)


