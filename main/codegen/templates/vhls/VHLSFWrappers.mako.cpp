//NO_AUTOREPLACE
#include "vhls_natypes.h"



<%! from time import strftime as time %>
<% 
import pdb
ziplist=pedecl.ziplist
IModnameHLS = 'I'+modname+'_hls'
%>\
<%
  import math
  sc2pass=[]
  vhlspass=[]
  scs_fifof_ins=[]
  scs_fifof_outs=[]
  scs_1regs=[]
  scs_regfile_ins=[]
  scs_regfile_outs=[]
  scs_bus_bram=[]
  scs_bram_ap_memory=[]
  scs_bram_ap_memory_i=[]
  scs_bram_ap_memory_o=[]
  scs_bram_ap_memory_io=[]
  scs_ram_ap_memory_i=[]
  scs_ram_ap_memory_o=[]
  scs_ram_ap_memory_io=[]
  scs_mbus=[]
  moreinfo = ', '.join([repr((i, z)) for s,i,z,x in ziplist])
  for s, i, z, _scs in ziplist:
    scdecl=''
    isOutput=False
    isInOut=False
    if i[0] == '&':
      i=i[1:]
      isOutput=True
    elif i[0] == '@':
      i=i[1:]
      isInOut=True
    if not _scs or _scs == '__fifo__':  # default FIFOF
      scdecl="FIFOF#("+s+") "+i;
      vhls_decl = s+" *"+i;
      if isOutput:
        scs_fifof_outs.append((s,i, _am.get_vhls_portname(s, i), z))
      else:
        scs_fifof_ins.append((s,i, _am.get_vhls_portname(s, i), z))
    elif _scs == '__bram__':
        scdecl="BRAM2Port#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
        vhls_decl=s+" "+i+"["+str(z)+"]";
        # DISABLING experimental pathway to apbus
        #scs_bus_bram.append((s,i, _am.get_vhls_portname(s, i), (int(math.ceil(math.log(z, 2))))))
        #scs_bram_ap_memory.append((s,i, _am.get_vhls_portname(s, i), (int(math.ceil(math.log(z, 2))))))
        tpl4 = (s,i, _am.get_vhls_portname(s, i), (int(math.ceil(math.log(z, 2)))))
        if isOutput:
          scs_bram_ap_memory_o.append(tpl4)
        elif isInOut:
          scs_bram_ap_memory_io.append(tpl4)
        else:
          scs_bram_ap_memory_i.append(tpl4)
               
    elif _scs == '__ram__':
        scdecl="MEMORY_IFC#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
        tpl4 = (s,i, _am.get_vhls_portname(s, i), (int(math.ceil(math.log(z, 2)))))
        if isOutput:
          scs_ram_ap_memory_o.append(tpl4)
        elif isInOut:
          scs_ram_ap_memory_io.append(tpl4)
        else:
          scs_ram_ap_memory_i.append(tpl4)
        vhls_decl=s+" "+i+"["+str(z)+"]";
    elif _scs == '__mbus__':
        scdecl="MEMORY_IFC#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
        scs_mbus.append((s,i, _am.get_vhls_portname(s, i), (int(math.ceil(math.log(z, 2))))))
        vhls_decl=s+" "+i+"["+str(z)+"]";
        vhls_decl="volatile " + s +" *"+i; # try array form too
    elif _scs == '__reg__':
      if z == 1:
        scdecl="Reg#("+s+") "+i;
        if isOutput:
          vhls_decl=s+" *"+i;
        else:
          vhls_decl=s+" "+i;
        scs_1regs.append((s,i,_am.get_vhls_portname(s,i)))
      else:
        scdecl="RegFile#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
        vhls_decl=s+" "+i+"["+str(z)+"]";
        if isOutput:
          scs_regfile_outs.append((s,i,_am.get_vhls_portname(s,i),(int(math.ceil(math.log(z, 2))))))
        else:
          scs_regfile_ins.append((s,i,_am.get_vhls_portname(s,i),(int(math.ceil(math.log(z, 2))))))
    sc2pass.append(scdecl) 
    vhlspass.append(vhls_decl)
  state_containers_to_pass =  ', '.join(sc2pass)
  vhls_declaration_list =  ', '.join(vhlspass)

  method_list=[]
  if(scs_1regs):
    method_list.extend(['set1reg'+str(i) for i in range(len(scs_1regs))])
  if(scs_regfile_ins):
    method_list.extend(['dataRegFileIn'+str(i)+', getRegFileInAddress'+str(i) for i in range(len(scs_regfile_ins))])
  if(scs_regfile_outs):
    method_list.extend(['dataRegFileOut'+str(i)+', getRegFileOutAddress'+str(i) for i in range(len(scs_regfile_outs))])
    
  if(scs_bram_ap_memory):
      method_list.extend(['dataBramApMemIn'+str(i)+', getBramApMemInAddress'+str(i) for i in range(len(scs_bram_ap_memory))])
      method_list.extend(['dataBramApMemOut'+str(i)+', getBramApMemOutAddress'+str(i) for i in range(len(scs_bram_ap_memory))])

  if(scs_bram_ap_memory_i):
      method_list.extend(['dataBramApMemIn'+str(i)+', getBramApMemInAddress'+str(i) for i in range(len(scs_bram_ap_memory_i))])
  if(scs_bram_ap_memory_o):
      method_list.extend(['dataBramApMemOut'+str(i)+', getBramApMemOutAddress'+str(i) for i in range(len(scs_bram_ap_memory_o))])
  if(scs_bram_ap_memory_io):
      method_list.extend(['dataBramApMemIn_io_'+str(i)+', getBramApMemInAddress_io_'+str(i) for i in range(len(scs_bram_ap_memory_io))])
      method_list.extend(['dataBramApMemOut_io_'+str(i)+', getBramApMemOutAddress_io_'+str(i) for i in range(len(scs_bram_ap_memory_io))])



  if(scs_bus_bram):
    method_list.extend(['brambus{}ReqNotFull, brambus{}RspNotEmpty, brambus{}ReadRsp, brambus{}ReqAddr, brambus{}ReqSize, brambus{}WriteData, brambus{}WriteReqEn'.format(i, i, i, i, i, i, i) for i in range(len(scs_bus_bram))])
  if(scs_mbus):
    method_list.extend(['mbus{}ReqNotFull, mbus{}RspNotEmpty, mbus{}ReadRsp, mbus{}ReqAddr, mbus{}ReqSize, mbus{}WriteData, mbus{}WriteReqEn'.format(i, i, i, i, i, i, i) for i in range(len(scs_mbus))])
  if(scs_fifof_ins or scs_fifof_outs):
    method_list.extend(['enDataIn'+str(i)+', data_in'+str(i) for i in range(len(scs_fifof_ins))] + 
    ['enDataOut'+str(i)+', data_out'+str(i) for i in range(len(scs_fifof_outs))])

  method_list = ', '.join(method_list)
%>\

void ${modname}(${vhls_declaration_list}) {
    /* avoid pure combinational modules */
    #pragma HLS latency min=1
%for index,(typename,iname,vhlsportname) in enumerate(scs_1regs):
    #pragma HLS INTERFACE ap_none port=${iname}
    #pragma HLS data_pack variable=${iname}

%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_ins):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_outs):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS data_pack variable=${iname}

%endfor 
## method Action data_in${index}(P p_dout);
## method Action enDataIn0();
%for index,(typename,iname,vhlsportname, tp_z) in enumerate(scs_fifof_ins):
    #pragma HLS INTERFACE ap_fifo port=${iname} depth=${tp_z}
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname, tp_z) in enumerate(scs_fifof_outs):
    #pragma HLS INTERFACE ap_fifo port=${iname} depth=${tp_z}
    #pragma HLS data_pack variable=${iname}

%endfor
## method R data_out0();
## method Action enDataOut0();
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_i):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS RESOURCE variable=${iname} core=RAM_1P_BRAM latency=1
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_o):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS RESOURCE variable=${iname} core=RAM_1P_BRAM latency=1
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_io):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS RESOURCE variable=${iname} core=RAM_2P_BRAM latency=1 /* make sure to both read and write to this port */
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_i):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS RESOURCE variable=${iname} core=RAM_1P_BRAM latency=1
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_o):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS RESOURCE variable=${iname} core=RAM_1P_BRAM latency=1
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_io):
    #pragma HLS INTERFACE ap_memory port=${iname}
    #pragma HLS RESOURCE variable=${iname} core=RAM_2P_BRAM latency=1 /* make sure to both read and write to this port */
    #pragma HLS data_pack variable=${iname}

%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
    #pragma HLS INTERFACE ap_bus port=${iname}
    #pragma HLS data_pack variable=${iname}
%endfor 
}

## vim: ft=mako
