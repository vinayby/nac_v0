#! /usr/bin/env python3
# -*- coding: utf-8 -*-
# 2017 vby
############################ vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
"""

"""
import os
import collections
import pdb
import xml.etree.ElementTree as ET
from optparse import OptionParser
from argparse import ArgumentParser

from collections import defaultdict
from pprint import pprint
import json
def dump_as_json(d, filename):
    with open(filename, "w") as fo:
        json.dump(d, fp=fo, indent=4)


def etree_to_dict(t):
    d = {t.tag: {} if t.attrib else None}
    children = list(t)
    if children:
        dd = defaultdict(list)
        for dc in map(etree_to_dict, children):
            for k, v in dc.items():
                dd[k].append(v)
        d = {t.tag: {k:v[0] if len(v) == 1 else v for k, v in dd.items()}}
    if t.attrib:
        d[t.tag].update(('@' + k, v) for k, v in t.attrib.items())
    if t.text:
        text = t.text.strip()
        if children or t.attrib:
            if text:
              d[t.tag]['#text'] = text
        else:
            d[t.tag] = text
    return d


def get_top_node_name(tableinfo):
    heads, tr = tableinfo
    return tr[1:][0]['tablecell'][0]['@contents'].strip()

def naspecific_demangling_for_latex(s):
    s = s.replace('mkNodeTask_','')
    s = s.replace('mkNetworkSimple','noc(PF)')
    s = s.replace('mkNetwork','noc(CF)')
    s = s.replace('mktopology','fnoc')
    s = s.replace('_','\_')
    s = s.replace('(','')
    s = s.replace(')','')
    return s

def dump_latex_tabular_with_selected_rowcolumnHeads(tableinfo, select_nodes, select_heads, args):
    heads, tr = tableinfo
    node_prop_d = collections.OrderedDict([(k,None) for k in select_nodes]) # establish the requested order
    node_modname_d = collections.OrderedDict()
    for r in tr[1:]:
        # cell list 
        cl = r['tablecell']
        node_, modname_ = cl[0]['@contents'].strip(),cl[1]['@contents'].strip()
        if node_ in select_nodes or modname_ in select_nodes:
            node_modname_d[node_] = modname_
            lcontents = [x['@contents'] for x in cl]
            if modname_ in select_nodes:
                node_prop_d[modname_] = list(zip(heads, lcontents))
                node_modname_d[modname_] = modname_
            else:
                node_prop_d[node_] = list(zip(heads, lcontents))

    for node_ in select_nodes:
        print(node_)
        ll = list(filter(lambda x: x[0] in select_heads, node_prop_d[node_]))
        llv = [v for k,v in ll]
        node_prop_d[node_]=llv
        
    
    # latex table column count and format string
    table_cols = 1+len(select_heads)
    table_colspecs = ' '.join(['c']*table_cols)
    # head line
    ssl = ['\t&'.join(['']+select_heads)]
    # content lines
    for k,v in node_prop_d.items():
        k=node_modname_d[k]
        #k=k.replace('_','\_')
        k=naspecific_demangling_for_latex(k)
        l = [k] + [str(e) for e in v]
        ssl.append('\t&'.join(l))
           
    ss = '\\\\\hline\n'.join(ssl)
    ss +='\\\\\hline' # end 

    sfinal = """
    \\begin{{table}}[h!]
    \centering 
    \caption{{{2}}}
    \\begin{{tabular}}{{{0}}}
    {1}
    \end{{tabular}}
    \end{{table}}
    """.format(table_colspecs, ss, args.annotation)
    
    print(sfinal)




def listselect_nodes(tableinfo):
    heads, tr = tableinfo
    for r in tr[1:]:
        # cell list
        cl = r['tablecell'] 
        if cl[0]['@contents'].strip() in select_nodes:
            rcontents = [x['@contents'] for x in cl]
            print(list(zip(heads,rcontents)))

    
def get_default_modules_of_interest(tableinfo): 
    heads, tr = tableinfo
    ofinterest = [get_top_node_name(tableinfo), 'nodes_', 'noc']
    all = [e['tablecell'][0]['@contents'].strip() for e in tr[1:]]
    lnodes = list(filter(lambda x: x.find('nodes_')!=-1 and x[0]!='(', all))
    rl = [get_top_node_name(tableinfo), 'noc'] + lnodes 
    return rl


def run():
    from configargparse import ArgParser, ArgumentDefaultsHelpFormatter, ArgumentDefaultsRawHelpFormatter
    parser = ArgParser()
    parser.formatter_class = ArgumentDefaultsHelpFormatter
    group1 = parser.add_argument_group("Core Arguments")
    group1.add('-c', '--my-config', required=False, is_config_file=True, help='config file path')
    group1.add('-a', '--annotation', default='',required=False, help='Latex Table Caption')
    group1.add('heir_xml',  help='the _heir.xml report for hierarchical resource usage')
    group1.add('-nl', '--nodelist', required=False,nargs='+', help="module names selected\n e.g. '-nl all' for mkTop and all nodes_*\nOr '-nl all innerMod1 innerMod2' for all plus the other two")
    group1.add('-hl', '--headlist', required=False,nargs='+', help="resource heads to list; specify 'all' for all heads")
    
    args = parser.parse_args()

    tree = ET.parse(args.heir_xml)
    root = tree.getroot()
    d = etree_to_dict(root)
    #dump_as_json("x.json")

    # table rows
    tr = d["RptDoc"]["section"]["table"]["tablerow"] 
    # header
    hdr = tr[0]['tableheader']
    heads = [h['@contents'] for h in hdr]
    tableinfo = (heads, tr) # heads and rows
    
    select_nodes = args.nodelist
    if 'all' in select_nodes:
        select_nodes.remove('all')
        select_nodes += get_default_modules_of_interest(tableinfo)

    if not select_nodes:
        #select_nodes = [get_top_node_name(tableinfo)]
        select_nodes = get_default_modules_of_interest(tableinfo)
    select_heads = args.headlist
    if select_heads and 'all' in select_heads:
#         select_heads = heads[2:] # skip heads: Instance, Module
        select_heads = [h for h in heads if h not in ['Instance', 'Module', 'SRLs', 'Logic LUTs']]
    if not select_heads:
        select_heads = ['Total LUTs', 'Logic LUTs', 'FFs']

    dump_latex_tabular_with_selected_rowcolumnHeads(tableinfo, select_nodes, select_heads, args)

run()
