#! /usr/bin/env python3
# -*- coding: utf-8 -*-
""" [2018] vbyk
"""
################## vim:fenc=utf-8 tabstop=8 expandtab shiftwidth=4 softtabstop=4

import sys
import os
import pdb
import sqlite3
"""
-- sample trace file format --
    tick:          2; tid: 4; ev_ts: top; lvl: 1; lno: 80; name: recv
    tick:         57; tid: 4; ev_ts: bottom; lvl: 1; lno: 80; name: recv
    tick:         58; tid: 4; ev_ts: top; lvl: 1; lno: 81; name: displaystmt
    tick:         60; tid: 4; ev_ts: bottom; lvl: 1; lno: 81; name: displaystmt
"""
trace_file = "trace.log"
known_key_types = {'tick': 'INTEGER', 'tid': 'INTEGER', 'lvl': 'INTEGER', 'lno': 'INTEGER', 'ev_ts':'TEXT', 'name': 'TEXT'}
with open(trace_file, 'r') as fh:
    lines = [l[:-1].replace(' ','').split(';') for l in fh if l.find('ev_ts')>0]
    keys = [e.split(':')[0] for e in lines[0]]
    valrecords = [[e.split(':')[1] for e in l] for l in lines]
    
    conn = sqlite3.connect('tracelog.db')
    dbc = conn.cursor()
    
    keys_schema = ['{} {}'.format(k, known_key_types[k] if k in known_key_types else 'TEXT') for k in keys]
    
    dbc.execute('CREATE TABLE IF NOT EXISTS natrace  ({})'.format(','.join(keys_schema)))
    dbc.executemany('INSERT INTO natrace VALUES ({})'.format(', '.join(len(keys)*['?'])),   [tuple(r) for r in valrecords])
    conn.commit()
    conn.close()


