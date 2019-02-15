#! /usr/bin/env python3
# -*- coding: utf-8 -*-
################## vim:fenc=utf-8 tabstop=8 expandtab shiftwidth=4 softtabstop=4

#---------------------------------------------------------------------------------------------------
na_basic_type_list = {        
        'float'     : (32,  'MPI_FLOAT'),
        'int'       : (32,  'MPI_INT'),
        'double'    : (64,  'MPI_DOUBLE'),
        'uint8_t'   : (8,   'MPI_UNSIGNED_CHAR'),
        'int8_t'    : (8,   'MPI_SIGNED_CHAR'),
        'uint16_t'  : (16,  'MPI_UNSIGNED_SHORT'),
        'int16_t'   : (16,  'MPI_SHORT'),
        'uint32_t'  : (32,  'MPI_UNSIGNED'),
        'uint64_t'  : (64,  'MPI_UNSIGNED_LONG')
        }
#---------------------------------------------------------------------------------------------------
class NotYetSupportedException(Exception):
    pass

class NotSupportedException(Exception):
    pass

class CompilationError(Exception):
    pass

#---------------------------------------------------------------------------------------------------
