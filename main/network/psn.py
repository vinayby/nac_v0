#! /usr/bin/env python3
# -*- coding: utf-8 -*-
""" [2018] vbyk
"""
################## vim:fenc=utf-8 tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import os
import pdb
import collections
from main.network import psn_util
#---------------------------------------------------------------------------------------------------
"""
PSN: Packet switched network 
    - (TODO) generate
    - parse and probe
"""
class PSN(object):

    def __init__(self, sysargs):
        self.dir = os.path.abspath(sysargs.nocdir)
        self.params = collections.OrderedDict()
        self.type, self.subtype, self.config = psn_util.detect_noc_type(self.dir)
        self.read_config_params()

    def read_config_params(self):
        def loadjson(filename):
            import json
            with open(filename, 'r') as fh:
                return json.load(fh)
        
        pl = []

        if self.type == 'fnoc':
            x = loadjson(self.config)
            pl = [(k, v) for k, v in x.items()]
        
        if self.type == 'connect':
            pl = psn_util.parse_connect_parameters(self.config)

        for k, v in pl: 
            self.params[k] = v
        assert 'USE_VIRTUAL_LINKS' in self.params and self.params['USE_VIRTUAL_LINKS'] == 'True', "Only CONNECT NoCs with USE_VIRTUAL_LINKS=True are supported"


    def is_connect_peek(self):
        return self.is_connect('peek')

    def is_connect_credit(self):
        return self.is_connect('credit')

    def is_fnoc_peek(self):
        return self.type == 'fnoc'

    def is_connect(self, subtype=None):
        if not subtype:
            return self.type == 'connect'
        else:
            return self.is_connect() and self.subtype == subtype

    def is_fnoc(self, subtype=None):
        if not subtype:
            return self.type == 'fnoc'
        else:
            return self.is_fnoc() and self.subtype == subtype

    def get_mkTopName(self):
        if self.type == 'fnoc':
            return 'mktopology'
        if self.type == 'connect':
            return 'mkNetwork' if self.subtype == 'credit' else 'mkNetworkSimple'
        raise NotSupportedException("network type")


