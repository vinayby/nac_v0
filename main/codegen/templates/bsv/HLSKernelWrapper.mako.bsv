<%! from time import strftime as time %>
<% 
import pdb
ziplist=pedecl.ziplist
IModnameHLS = 'I'+modname+'_hls'
uses_mbus = '__mbus__' in [k for _,_,_,k in ziplist]
uses_ram = '__ram__' in [k for _,_,_,k in ziplist]
uses_memifc1 = uses_mbus or uses_ram 
USE_OLD_SCHEDULE_SPECS = False
%>\
import DefaultValue::*;
import NATypes::*;
import GetPut::*;
import FIFO::*;
import FIFOF::*;
import BRAM::*;
import Connectable::*;
import GetPut::*;
import Vector::*;
import RegFile::*;
import DebugTrace::*;
%if uses_memifc1:
import LeapBram::*;
import Memory_interface::*;
%endif
%if uses_mbus:
  interface HLS_AP_BUS_IFC#(type tpd, type tpa, type tpdlen);
  method Action reqNotFull();
//   method Action rspNotEmpty();
  method Action readRsp( tpd resp);
  method tpa reqAddr();
  method tpdlen reqSize();
  method tpd writeData();
  method Bool writeReqEn();
  endinterface
  `define MBUS_DEBUG_0
%endif 
<%
  import math
  sc2pass=[]
  scs_fifof_ins=[]
  scs_fifof_outs=[]
  scs_1regs=[]
  scs_1regs_i=[]
  scs_1regs_o=[]
  scs_1regs_io=[]
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
      if isOutput:
        scs_fifof_outs.append((s,i, _am.get_vhls_portname(s, i)))
      else:
        scs_fifof_ins.append((s,i, _am.get_vhls_portname(s, i)))
    elif _scs == '__bram__':
        scdecl="BRAM2Port#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
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
    elif _scs == '__mbus__':
        scdecl="MEMORY_IFC#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
        scs_mbus.append((s,i, _am.get_vhls_portname(s, i), (int(math.ceil(math.log(z, 2))))))
    elif _scs == '__reg__':
      if z == 1:
        scdecl="Reg#("+s+") "+i;
        #scs_1regs.append((s,i,_am.get_vhls_portname(s,i)))
        if isOutput:
          scs_1regs_o.append((s,i,_am.get_vhls_portname(s,i)))
        elif isInOut:
          scs_1regs_io.append((s,i,_am.get_vhls_portname(s,i)))
        else:
          scs_1regs_i.append((s,i,_am.get_vhls_portname(s,i)))
      else:
        scdecl="RegFile#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
        if isOutput:
          scs_regfile_outs.append((s,i,_am.get_vhls_portname(s,i),(int(math.ceil(math.log(z, 2))))))
        else:
          scs_regfile_ins.append((s,i,_am.get_vhls_portname(s,i),(int(math.ceil(math.log(z, 2))))))
    sc2pass.append(scdecl) 
  state_containers_to_pass =  ', '.join(sc2pass)

  method_list=[]
  import collections
  method_dict=collections.OrderedDict()
  l = []
  if(scs_1regs): # this will be []
    pdb.set_trace()
    l.extend(['set1reg'+str(i) for i in range(len(scs_1regs))]) 

  l = []
  if(scs_1regs_i):
    l.extend(['set1reg'+str(i) for i in range(len(scs_1regs_i))])
  method_list.extend(l)
  method_dict['reg1_set'] = l

  l = []
  if(scs_1regs_o):
    l.extend(['get1reg'+str(i) for i in range(len(scs_1regs_o))])
  if(scs_1regs_io):
      pdb.set_trace()
      pass 
  method_list.extend(l)
  method_dict['reg1_get'] = l


  l=[]
  if(scs_regfile_ins):
    l.extend(['dataRegFileIn'+str(i)+', getRegFileInAddress'+str(i) for i in range(len(scs_regfile_ins))])
  if(scs_regfile_outs):
    l.extend(['dataRegFileOut'+str(i)+', getRegFileOutAddress'+str(i) for i in range(len(scs_regfile_outs))])

  method_list.extend(l)
  method_dict['regfile']=l
  
  l=[]
  if(scs_bram_ap_memory):
      l.extend(['dataBramApMemIn'+str(i)+', getBramApMemInAddress'+str(i) for i in range(len(scs_bram_ap_memory))])
      l.extend(['dataBramApMemOut'+str(i)+', getBramApMemOutAddress'+str(i) for i in range(len(scs_bram_ap_memory))])

  if(scs_bram_ap_memory_i):
      l.extend(['dataBramApMemIn'+str(i)+', getBramApMemInAddress'+str(i) for i in range(len(scs_bram_ap_memory_i))])
  if(scs_bram_ap_memory_o):
      l.extend(['dataBramApMemOut'+str(i)+', getBramApMemOutAddress'+str(i) for i in range(len(scs_bram_ap_memory_o))])
  if(scs_bram_ap_memory_io):
      l.extend(['dataBramApMemIn_io_'+str(i)+', getBramApMemInAddress_io_'+str(i) for i in range(len(scs_bram_ap_memory_io))])
      l.extend(['dataBramApMemOut_io_'+str(i)+', getBramApMemOutAddress_io_'+str(i) for i in range(len(scs_bram_ap_memory_io))])
      
  method_list.extend(l)
  method_dict['bram_ap_memory']=l

  l=[]
  if(scs_ram_ap_memory_i):
      l.extend(['dataramApMemIn'+str(i)+', getramApMemInAddress'+str(i) for i in range(len(scs_ram_ap_memory_i))])
  if(scs_ram_ap_memory_o):
      l.extend(['dataramApMemOut'+str(i)+', getramApMemOutAddress'+str(i) for i in range(len(scs_ram_ap_memory_o))])
  if(scs_ram_ap_memory_io):
      l.extend(['dataramApMemIn_io_'+str(i)+', getramApMemInAddress_io_'+str(i) for i in range(len(scs_ram_ap_memory_io))])
      l.extend(['dataramApMemOut_io_'+str(i)+', getramApMemOutAddress_io_'+str(i) for i in range(len(scs_ram_ap_memory_io))])
  method_list.extend(l)
  method_dict['ram_ap_memory'] = l




  l=[]
  if(scs_bus_bram):
    l.extend(['brambus{0}ReqNotFull, brambus{0}RspNotEmpty, brambus{0}ReadRsp, brambus{0}ReqAddr, brambus{0}ReqSize, brambus{0}WriteData, brambus{0}WriteReqEn'.format(i) for i in range(len(scs_bus_bram))])
  method_list.extend(l)
  method_dict['bus_bram'] = l

  l=[]  
  if(scs_mbus):
    l.extend(['mbus{0}ReqNotFull, mbus{0}ReadRsp, mbus{0}ReqAddr, mbus{0}ReqSize, mbus{0}WriteData, mbus{0}WriteReqEn'.format(i) for i in range(len(scs_mbus))])
  method_list.extend(l)
  method_dict['mbus'] = l

  l=[]
  if(scs_fifof_outs):
    l.extend(['enDataOut'+str(i)+', data_out'+str(i) for i in range(len(scs_fifof_outs))])
  method_list.extend(l)
  method_dict['fifo_out'] = l

  l=[]
  if(scs_fifof_ins):
    l.extend(['enDataIn'+str(i)+', data_in'+str(i) for i in range(len(scs_fifof_ins))]) 
  method_list.extend(l)
  method_dict['fifo_in'] = l

  method_list = ', '.join(method_list)
%>\

<%def name="SCHEDULE_(how, key1, key2, one_at_a_time=False)">
  <%
    if how == 'SB' or how == 'SBR':
      one_at_a_time = True
  %>
  %if key1 in method_dict and key2 in method_dict:
      %if method_dict[key1] and method_dict[key2]:
      // ${key1} vs. ${key2}
##         %if how == 'CF':
            %if not one_at_a_time:
                schedule (${', '.join(method_dict[key1])}) ${how} (${', '.join(method_dict[key2])});
            %else:
              %for a, b in zip(method_dict[key1], method_dict[key2]):
                schedule (${a}) ${how} (${b});
              %endfor 
            %endif
##      %elif how == 'SB': ## 
##          ## handle individually
##          %for a, b in zip(method_dict[key1], method_dict[key2]):
##              schedule (${a}) ${how} (${b});
##          %endfor 
##      %endif
      %endif
  %endif
</%def>\
<%def name="SCHEDULE_CF_BETWEEN_INSTANCES(key)">
  %if key in method_dict and len(method_dict[key])>1:
      <%
        import itertools
        instance_combs = list(itertools.combinations(method_dict[key], 2))
       %>\
       %for a, b in instance_combs:
           schedule (${a}) CF (${b});
       %endfor 
  %endif
</%def>\

//////////////////////////////////////////////////////////////////////////////////////
//BVI Interface Declaration (Imodname_hls)
//BVI Module Import         (import "BVI" modname = mkModname_hls(Imodname_hls);)

interface ${IModnameHLS};
 method Action start();
 method Bool isReady();
 method Bool isIdle();
 method Bool isDone();
 //MAIN METHODS
%for index,(typename,iname,vhlsportname) in enumerate(scs_1regs):
    method Action set1reg${index}(${typename} ${vhlsportname});
%endfor 
%for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_i):
    method Action set1reg${index}(${typename} ${vhlsportname});
%endfor 
%for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_o):
    method ${typename} get1reg${index}();
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_ins):
    method Action dataRegFileIn${index}(${typename} ${vhlsportname}_q0);
    method ActionValue#(Bit#(${tpawidth})) getRegFileInAddress${index}();
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_outs):
    method ${typename} dataRegFileOut${index}();
    method ActionValue#(Bit#(${tpawidth})) getRegFileOutAddress${index}();
%endfor 
## method Action data_in${index}(P p_dout);
## method Action enDataIn0();
%for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_ins):
    method Action data_in${index}(${typename} ${vhlsportname}_dout);
    method Action enDataIn${index}();
%endfor 

%for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_outs):
    method ${typename} data_out${index};
    method Action enDataOut${index};
%endfor 
## method R data_out0();
## method Action enDataOut0();

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_i):
  //ins
    method Action dataBramApMemIn${index}(${typename} ${vhlsportname}_q0);
    method ActionValue#(Bit#(${tpawidth})) getBramApMemInAddress${index}();
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_o):
  //outs
    method ${typename} dataBramApMemOut${index}();
    method ActionValue#(Bit#(${tpawidth})) getBramApMemOutAddress${index}();
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_io):
  //ins
     method Action dataBramApMemIn_io_${index}(${typename} ${vhlsportname}_q0);
    method ActionValue#(Bit#(${tpawidth})) getBramApMemInAddress_io_${index}();
  //outs
    method ${typename} dataBramApMemOut_io_${index}();
    method ActionValue#(Bit#(${tpawidth})) getBramApMemOutAddress_io_${index}();
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_i):
  //ins
    method Action dataramApMemIn${index}(${typename} ${vhlsportname}_q0);
    method ActionValue#(Bit#(${tpawidth})) getramApMemInAddress${index}();
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_o):
  //outs
    method ${typename} dataramApMemOut${index}();
    method ActionValue#(Bit#(${tpawidth})) getramApMemOutAddress${index}();
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_io):
  //ins
     method Action dataramApMemIn_io_${index}(${typename} ${vhlsportname}_q0);
    method ActionValue#(Bit#(${tpawidth})) getramApMemInAddress_io_${index}();
  //outs
    method ${typename} dataramApMemOut_io_${index}();
    method ActionValue#(Bit#(${tpawidth})) getramApMemOutAddress_io_${index}();
%endfor

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bus_bram):
    //inputs
        method Action brambus${index}ReqNotFull();
        method Action brambus${index}RspNotEmpty();
        method Action brambus${index}ReadRsp(${typename} ${vhlsportname}_datain);
        //outputs
        method Bit#(${tpawidth}) brambus${index}ReqAddr();
        method Bit#(${tpawidth}) brambus${index}ReqSize();
        method ${typename} brambus${index}WriteData();
        method Bool brambus${index}WriteReqEn();
%endfor        
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
    //inputs
        method Action mbus${index}ReqNotFull();
//         method Action mbus${index}RspNotEmpty();
        method Action mbus${index}ReadRsp(${typename} ${vhlsportname}_datain);
        //outputs
        method Bit#(${tpawidth}) mbus${index}ReqAddr();
        method Bit#(32) mbus${index}ReqSize();
        method ${typename} mbus${index}WriteData();
        method Bool mbus${index}WriteReqEn();
%endfor        

endinterface 

import "BVI" ${pedecl.name}_0 = 
module mk${modname}_hls(${IModnameHLS});
  default_clock clk;
  default_reset rst_RST_N;
  input_clock clk (ap_clk) <- exposeCurrentClock;
  input_reset rst_RST_N (ap_rst_n) clocked_by(clk) <- exposeCurrentReset;
  //METHODS
  method start() enable(ap_start);
  method ap_idle  isIdle();
  method ap_done  isDone();
  method ap_ready isReady();
  //MAIN
%for index,(typename,iname,vhlsportname) in enumerate(scs_1regs):
    method set1reg${index}(${vhlsportname}) enable( (*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
%endfor 
%for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_i):
    method set1reg${index}(${vhlsportname}) enable( (*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
%endfor 
%for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_o):
    method ${vhlsportname} get1reg${index}(); //enable( (*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_ins):
    method dataRegFileIn${index}(${vhlsportname}_q0) enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
    method ${vhlsportname}_address0 getRegFileInAddress${index}() enable(${vhlsportname}_ce0);
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_outs):
    method ${vhlsportname}_d0 dataRegFileOut${index}();
    method ${vhlsportname}_address0 getRegFileOutAddress${index}() enable(${vhlsportname}_ce0) ready(${vhlsportname}_we0);
%endfor 

 ## method data_in${index}(p_dout) enable( (*inhigh*) V_UNUSED1 ) ready(p_read);
 ## method enDataIn0() enable(p_empty_n);
 %for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_ins):
     method data_in${index}(${vhlsportname}_dout) enable ( (*inhigh*) V_UNUSED_${s}${vhlsportname}${index} ) ready(${vhlsportname}_read);
     method enDataIn${index}() enable(${vhlsportname}_empty_n);
  %endfor 

  ##method r_din data_out0() ready(r_write);
  ##method       enDataOut0() enable(r_full_n);
%for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_outs):
    method ${vhlsportname}_din data_out${index}() ready(${vhlsportname}_write);
    method                   enDataOut${index}() enable(${vhlsportname}_full_n);
%endfor 

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory):
%if True:
    method dataBramApMemIn${index}(${vhlsportname}_q0) enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
    method ${vhlsportname}_address0 getBramApMemInAddress${index}() enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_1 ) ready(${vhlsportname}_ce0);
    method ${vhlsportname}_d0 dataBramApMemOut${index}() ready(${vhlsportname}_we0);
    method ${vhlsportname}_address0 getBramApMemOutAddress${index}() enable((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_2 ) ready(${vhlsportname}_ce0);
%else:
    method dataBramApMemIn${index}(${vhlsportname}_q0) enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
    method ${vhlsportname}_address0 getBramApMemInAddress${index}() enable(${vhlsportname}_ce0);
    method ${vhlsportname}_d0 dataBramApMemOut${index}();
    method ${vhlsportname}_address0 getBramApMemOutAddress${index}() enable(${vhlsportname}_ce0) ready(${vhlsportname}_we0);
%endif
%endfor

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_i):
    method dataBramApMemIn${index}(${vhlsportname}_q0) enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
    method ${vhlsportname}_address0 getBramApMemInAddress${index}() enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_1 ) ready(${vhlsportname}_ce0);
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_o):
    method ${vhlsportname}_d0 dataBramApMemOut${index}() ready(${vhlsportname}_we0);
    method ${vhlsportname}_address0 getBramApMemOutAddress${index}() enable((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_2 ) ready(${vhlsportname}_ce0);
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_io):
    //NOT IMPLEMENTED YET
    //ins are port0
    method dataBramApMemIn_io_${index}(${vhlsportname}_q0) enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
    method ${vhlsportname}_address0 getBramApMemInAddress_io_${index}() enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_1 ) ready(${vhlsportname}_ce0);
    //outs are port1 with #pragma HLS RESOURCE variable=p core=RAM_2P_BRAM latency=k
    method ${vhlsportname}_d1 dataBramApMemOut_io_${index}() ready(${vhlsportname}_we1);
    method ${vhlsportname}_address1 getBramApMemOutAddress_io_${index}() enable((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_2 ) ready(${vhlsportname}_ce1);
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_i):
    method dataramApMemIn${index}(${vhlsportname}_q0) enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
    method ${vhlsportname}_address0 getramApMemInAddress${index}() enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_1 ) ready(${vhlsportname}_ce0);
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_o):
    method ${vhlsportname}_d0 dataramApMemOut${index}() ready(${vhlsportname}_we0);
    method ${vhlsportname}_address0 getramApMemOutAddress${index}() enable((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_2 ) ready(${vhlsportname}_ce0);
%endfor 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_io):
    //NOT IMPLEMENTED YET
    //ins are port0
    method dataramApMemIn_io_${index}(${vhlsportname}_q0) enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index} );
    method ${vhlsportname}_address0 getramApMemInAddress_io_${index}() enable ((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_1 ) ready(${vhlsportname}_ce0);
    //outs are port1 with #pragma HLS RESOURCE variable=p core=RAM_2P_ram latency=k
    method ${vhlsportname}_d1 dataramApMemOut_io_${index}() ready(${vhlsportname}_we1);
    method ${vhlsportname}_address1 getramApMemOutAddress_io_${index}() enable((*inhigh*) V_UNUSED_${s}${vhlsportname}${index}_2 ) ready(${vhlsportname}_ce1);
%endfor 

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bus_bram):
    //inputs
method brambus${index}ReqNotFull() enable(${vhlsportname}_req_full_n);
method brambus${index}RspNotEmpty() enable(${vhlsportname}_rsp_empty_n);    
method brambus${index}ReadRsp(${vhlsportname}_datain) enable( (*inhigh*)  V_UNUSED_${s}${vhlsportname}${index}) ready(${vhlsportname}_rsp_read);    
    //outputs
    method ${vhlsportname}_address brambus${index}ReqAddr() ready(${vhlsportname}_req_write);
    method ${vhlsportname}_size brambus${index}ReqSize() ready(${vhlsportname}_req_write);
    method ${vhlsportname}_dataout brambus${index}WriteData() ready(${vhlsportname}_req_write);
    method ${vhlsportname}_req_din brambus${index}WriteReqEn() ready(${vhlsportname}_req_write);
%endfor 

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
    //inputs
method mbus${index}ReqNotFull() enable(${vhlsportname}_req_full_n);
// method mbus${index}RspNotEmpty() enable(${vhlsportname}_rsp_empty_n);    
// method mbus${index}ReadRsp(${vhlsportname}_datain) enable( (*inhigh*)  V_UNUSED_${s}${vhlsportname}${index}) ready(${vhlsportname}_rsp_read);    
   method mbus${index}ReadRsp(${vhlsportname}_datain) enable(${vhlsportname}_rsp_empty_n);    
    //outputs
    method ${vhlsportname}_address mbus${index}ReqAddr() ready(${vhlsportname}_req_write);
    method ${vhlsportname}_size mbus${index}ReqSize() ready(${vhlsportname}_req_write);
    method ${vhlsportname}_dataout mbus${index}WriteData() ready(${vhlsportname}_req_write);
    method ${vhlsportname}_req_din mbus${index}WriteReqEn() ready(${vhlsportname}_req_write);
%endfor 

%if USE_OLD_SCHEDULE_SPECS:
  //TODO change schedule specs per https://github.com/LEAP-Core/leap-examples/blob/master/modules/apps/examples/hls_ap_bus_test/leap_model/hls-core-bsv-wrapper.bsv
  schedule (
  start, isIdle, isDone, isReady, 
  ##enDataIn0, data_in${index}, enDataOut0, data_out0
  ${method_list}
  ) CF (
  start, isIdle, isDone, isReady,
  ##enDataIn0, data_in${index}, enDataOut0, data_out0
  ${method_list}
  );
%else:
  schedule start C start;
  schedule (isIdle, isDone, isReady) CF (isIdle, isDone, isReady);
  schedule start CF (isIdle, isDone, isReady);
  schedule (start, isIdle, isDone, isReady) CF (${method_list}); 
  ## all methods 
 
  // intergroup CF 
  
  ${SCHEDULE_(how='CF',key1='fifo_in', key2='mbus')}
  ${SCHEDULE_(how='CF',key1='fifo_in', key2='bram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='fifo_in', key2='ram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='fifo_in', key2='regfile')}
  ${SCHEDULE_(how='CF',key1='fifo_in', key2='reg1_set')}
  ${SCHEDULE_(how='CF',key1='fifo_in', key2='reg1_get')}
  ${SCHEDULE_(how='CF',key1='fifo_in', key2='fifo_out')}
  
  ${SCHEDULE_(how='CF',key1='fifo_out', key2='mbus')}
  ${SCHEDULE_(how='CF',key1='fifo_out', key2='bram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='fifo_out', key2='ram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='fifo_out', key2='regfile')}
  ${SCHEDULE_(how='CF',key1='fifo_out', key2='reg1_set')}
  ${SCHEDULE_(how='CF',key1='fifo_out', key2='reg1_get')}
  
  ${SCHEDULE_(how='CF',key1='mbus', key2='bram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='mbus', key2='ram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='mbus', key2='regfile')}
  ${SCHEDULE_(how='CF',key1='mbus', key2='reg1_set')}
  ${SCHEDULE_(how='CF',key1='mbus', key2='reg1_get')}
  
  ${SCHEDULE_(how='CF',key1='bram_ap_memory', key2='ram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='bram_ap_memory', key2='reg1_set')}
  ${SCHEDULE_(how='CF',key1='bram_ap_memory', key2='reg1_get')}
  ${SCHEDULE_(how='CF',key1='bram_ap_memory', key2='regfile')}
  
  ${SCHEDULE_(how='CF',key1='ram_ap_memory', key2='regfile')}
  ${SCHEDULE_(how='CF',key1='ram_ap_memory', key2='reg1_set')}
  ${SCHEDULE_(how='CF',key1='ram_ap_memory', key2='reg1_get')}
  
  ${SCHEDULE_(how='CF',key1='regfile', key2='reg1_set')}
  ${SCHEDULE_(how='CF',key1='regfile', key2='reg1_get')}

  ## special case read-read CF, write-write SBR
  ${SCHEDULE_(how='CF',key1='reg1_get', key2='reg1_get', one_at_a_time=True)}
  ${SCHEDULE_(how='SBR',key1='reg1_set', key2='reg1_set', one_at_a_time=True)}

  ## special case: write SA read; but only SB is allowed in BVI
  ${SCHEDULE_(how='SB',key1='reg1_get', key2='reg1_set')}

  // multiple items of the same type mark CF
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='fifo_in')}
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='fifo_out')}
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='mbus')}
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='bram_ap_memory')}
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='ram_ap_memory')}
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='reg1_set')}
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='reg1_get')} 
  ${SCHEDULE_CF_BETWEEN_INSTANCES(key='regfile')}
  
  // TODO marking self-self CF for the following for now
  
  ##${SCHEDULE_(how='CF',key1='f'mbus', key2='mbus')}
  ${SCHEDULE_(how='CF',key1='bram_ap_memory', key2='bram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='ram_ap_memory', key2='ram_ap_memory')}
  ${SCHEDULE_(how='CF',key1='regfile', key2='regfile')}
  ##${SCHEDULE_(how='CF',key1='fifo_in', key2='fifo_in')}
  ##${SCHEDULE_(how='CF',key1='fifo_out', key2='fifo_out')}

  // marking C/CF for fifos 
  %if 'fifo_in' in method_dict:
  %for method_csv in method_dict['fifo_in']:
  %for enDataIn, data_in in [method_csv.split(',')[i:i + 2] for i in range(0, len(method_csv.split(',')), 2)]:
    ## list chunked in groups of 2
    schedule ${enDataIn} C ${enDataIn};
    schedule ${data_in} CF (${enDataIn}, ${data_in});
  %endfor 
  %endfor
  %endif 
  
  %if 'fifo_out' in method_dict:
  %for method_csv in method_dict['fifo_out']:
  %for enDataOut, data_out in [method_csv.split(',')[i:i + 2] for i in range(0, len(method_csv.split(',')), 2)]:
    ## list chunked in groups of 2
    schedule ${enDataOut} C ${enDataOut};
    schedule ${data_out} CF (${enDataOut}, ${data_out});
  %endfor 
  %endfor 
  %endif
  
  // marking C/CF for mbus
  %if 'mbus' in method_dict:
  %for method_csv in method_dict['mbus']:
  %for rnf, rr, ra, rz, wr, wren in [method_csv.split(',')[i:i + 6] for i in range(0, len(method_csv.split(',')), 6)]:
    ## ORDER ref: ['mbus{0}ReqNotFull, mbus{0}ReadRsp, mbus{0}ReqAddr, mbus{0}ReqSize, mbus{0}WriteData, mbus{0}WriteReqEn']
    ## list chunked in groups of 6
    schedule ${rnf} C  ${rnf};
    schedule ${rnf} CF (${', '.join([rr, ra, rz, wr, wren])});
    schedule ${rr}  C  ${rr};
    schedule ${rr}  CF (${', '.join([    ra, rz, wr, wren])});
    schedule (${', '.join([    ra, rz, wr, wren])}) CF 
             (${', '.join([    ra, rz, wr, wren])});
  %endfor
  %endfor
  %endif

  // marking schedule for reg1
##   %if 'reg1_set' in method_dict and method_dict['reg1_set']
##   %endif 

%endif  
endmodule 

//Cover
interface ${IModnameHLS}_bundles;
//scs INFIFOs
//scs OUTFIFOs 
//Handover to the raw HLS-BVI layer
 interface ${IModnameHLS} raw;
//scs REGs, REGFILEs
//scs BRAMs
//scs MBUSes
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
    interface HLS_AP_BUS_IFC#(${typename}, Bit#(${tpawidth}), Bit#(32)) mbus${index}; 
%endfor    
endinterface 

module mk${modname}_hls_bundles(${IModnameHLS}_bundles);
 let w${modname} <- mk${modname}_hls;
  
 %for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
     //interface HLS_AP_BUS_IFC#(SizeOf#(${typename}), SizeOf#(Bit#(${tpawidth}))) mbus${index}; 
     interface mbus${index} = 
     interface HLS_AP_BUS_IFC#(${typename}, Bit#(${tpawidth}), Bit#(32))
       			method Action reqNotFull();
                w${modname}.mbus${index}ReqNotFull();
            endmethod
//              method Action rspNotEmpty();
//                  w${modname}.mbus${index}RspNotEmpty();
//              endmethod
            method Action readRsp(${typename} resp);
                w${modname}.mbus${index}ReadRsp(resp);
            endmethod
            method Bit#(${tpawidth}) reqAddr() = w${modname}.mbus${index}ReqAddr();
            method Bit#(32) reqSize() = w${modname}.mbus${index}ReqSize();
            method ${typename} writeData() = w${modname}.mbus${index}WriteData();
            method Bool writeReqEn() = w${modname}.mbus${index}WriteReqEn();
     endinterface;
 %endfor    
 interface raw = w${modname};
endmodule 


interface ${'I'+modname};
method Action start();
method Bool done();
##interface HLS_AP_FIFO_IN_IFC#(P) fifoInPort0;
##interface HLS_AP_FIFO_OUT_IFC#(R) fifoOutPort0;
endinterface 
<%doc> ## DISABLE for now
module mk${modname}(${state_containers_to_pass}, ${'I'+modname} ifc);
  Reg#(KState) ks <- mkReg(IDLE);
  //----------begin support logic ---------------
  let core <- mk${modname}_hls_bundles;
	let w${modname} = core.raw;
  rule rstart(ks == RUNNING);
    w${modname}.start();
  endrule 
  rule rfinish(ks == RUNNING &&  w${modname}.isDone());
    ks <= FINISH;
  endrule 

  %for index,(typename,iname,vhlsportname) in enumerate(scs_1regs):
      rule set1reg${index}(ks == RUNNING);
       w${modname}.set1reg${index}(${iname});
      endrule 
  %endfor 
  %for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_i):
      rule set1reg${index}(ks == RUNNING);
       w${modname}.set1reg${index}(${iname});
      endrule 
  %endfor 
  %for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_o):
      rule get1reg${index}(ks == RUNNING);
       //w${modname}.set1reg${index}(${iname});
       ${iname} <= w${modname}.get1reg${index}();
      endrule 
  %endfor 
  %for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_ins):
      rule dataRegFileIn${index} (ks == RUNNING);
        let addr_${iname} <- w${modname}.getRegFileInAddress${index}();
        w${modname}.dataRegFileIn${index}(${iname}.sub(addr_${iname}));
      endrule 
  %endfor
  %for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_outs):
      rule dataRegFileOut${index}(ks == RUNNING);
        let addr_${iname} <- w${modname}.getRegFileOutAddress${index}();
        ${iname}.upd(addr_${iname}, w${modname}.dataRegFileOut${index}());
      endrule 
  %endfor


##(* fire_when_enabled *)
##rule enDataIn0(ks == RUNNING && p.notEmpty);
##  w${modname}.enDataIn0();
##endrule 
##(* fire_when_enabled *)
##rule enDataOut0(ks == RUNNING && r.notFull);
##  w${modname}.enDataOut0();
##endrule 
%for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_ins):
    //(* fire_when_enabled *)
    rule enDataIn${index}(ks == RUNNING && ${iname}.notEmpty);
      w${modname}.enDataIn${index}();
    endrule 
    
    rule data_in${index}(True);
      w${modname}.data_in${index}(${iname}.first); ${iname}.deq;
    endrule 
%endfor    
%for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_outs):
    //(* fire_when_enabled *)
    rule enDataOut${index}(ks == RUNNING && ${iname}.notFull);
      w${modname}.enDataOut${index}();
    endrule 
    //(* fire_when_enabled *)
    rule data_out${index}(True);
    let d = w${modname}.data_out${index}(); ${iname}.enq(d);
    endrule 
%endfor    

##rule data_in${index}(True);
##  w${modname}.data_in${index}(p.first); p.deq;
##endrule 
##
##(* fire_when_enabled *)
##rule data_out0(True);
##  let d = w${modname}.data_out0(); r.enq(d);
##endrule 

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_i):
      rule dataBramApMemIn${index} (ks == RUNNING);
      let _aa <- w${modname}.getBramApMemInAddress${index}();
       // w${modname}.dataBramApMemIn${index}(${iname}.sub(_aa));
       ${iname}.portB.request.put(BRAMRequest{write:False,responseOnWrite:False,address:_aa});
      endrule 
      rule dataBramApMemIn${index}Get (ks == RUNNING);
        let _dd<-${iname}.portB.response.get;
        w${modname}.dataBramApMemIn${index}(_dd);
      endrule
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_o):
      rule dataBramApMemOut${index}(ks == RUNNING);
        let _aa <- w${modname}.getBramApMemOutAddress${index}();
        //${iname}.upd(_aa, w${modname}.dataBramApMemOut${index}());
        ${iname}.portB.request.put(BRAMRequest{write:True,responseOnWrite:False,address:_aa,datain:w${modname}.dataBramApMemOut${index}()});
      endrule 
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_io):
      rule dataBramApMemIn_io_${index} (ks == RUNNING);
        let _aa <- w${modname}.getBramApMemInAddress_io_${index}();
       // w${modname}.dataBramApMemIn${index}(${iname}.sub(_aa));
       ${iname}.portB.request.put(BRAMRequest{write:False,responseOnWrite:False,address:_aa});
      endrule 
      rule dataBramApMemIn_io_${index}Get (ks == RUNNING);
      let _dd<-${iname}.portB.response.get;
      w${modname}.dataBramApMemIn_io_${index}(_dd);
      endrule
      rule dataBramApMemOut$_io_${index}(ks == RUNNING);
        let _aa <- w${modname}.getBramApMemOutAddress_io_${index}();
        //${iname}.upd(_aa, w${modname}.dataBramApMemOut${index}());
        ${iname}.portB.request.put(BRAMRequest{write:True,responseOnWrite:False,address:_aa,datain:w${modname}.dataBramApMemOut_io_${index}()});
      endrule 

%endfor

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_i):
      rule dataramApMemIn${index} (ks == RUNNING);
      let _aa <- w${modname}.getramApMemInAddress${index}();
       ${iname}.readReq(_aa);
      endrule 
      rule dataramApMemIn${index}Get (ks == RUNNING);
        let _dd<-${iname}.readRsp();
        w${modname}.dataramApMemIn${index}(_dd);
      endrule
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_o):
      rule dataramApMemOut${index}(ks == RUNNING);
        let _aa <- w${modname}.getramApMemOutAddress${index}();
        ${iname}.write(_aa, w${modname}.dataramApMemOut${index}());
      endrule 
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_io):
      rule dataramApMemIn_io_${index} (ks == RUNNING);
        let _aa <- w${modname}.getramApMemInAddress_io_${index}();
        ${iname}.readReq(_aa); 
      endrule 
      rule dataramApMemIn_io_${index}Get (ks == RUNNING);
      let _dd<-${iname}.readRsp();
      w${modname}.dataramApMemIn_io_${index}(_dd);
      endrule
      rule dataramApMemOut$_io_${index}(ks == RUNNING);
        let _aa <- w${modname}.getramApMemOutAddress_io_${index}();
        ${iname}.write(_aa, w${modname}.dataramApMemOut_io_${index}());
      endrule 

%endfor


%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory):
      rule dataBramApMemIn${index} (ks == RUNNING);
        let _aa <- w${modname}.getBramApMemInAddress${index}();
       // w${modname}.dataBramApMemIn${index}(${iname}.sub(_aa));
       ${iname}.portB.request.put(BRAMRequest{write:False,responseOnWrite:False,address:_aa});
      endrule 
      rule dataBramApMemIn${index}Get (ks == RUNNING);
      let _dd<-${iname}.portB.response.get;
      w${modname}.dataBramApMemIn${index}(_dd);
      endrule
      rule dataBramApMemOut${index}(ks == RUNNING);
        let _aa <- w${modname}.getBramApMemOutAddress${index}();
        //${iname}.upd(_aa, w${modname}.dataBramApMemOut${index}());
        ${iname}.portB.request.put(BRAMRequest{write:True,responseOnWrite:False,address:_aa,datain:w${modname}.dataBramApMemOut${index}()});
      endrule 
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bus_bram):
    //(* fire_when_enabled *)
    rule brambus${index}WriteReq ( w${modname}.brambus${index}WriteReqEn );

        Bit#(${tpawidth}) a = w${modname}.brambus${index}ReqAddr();
        ${typename} d = w${modname}.brambus${index}WriteData;
        //reqFifo.enq(tuple3(a,d,True));
				${iname}.portB.request.put(BRAMRequest{write: True, responseOnWrite: False, address: a, datain: d});
    endrule
    //(* fire_when_enabled *)
    rule brambus${index}ReadReq(!w${modname}.brambus${index}WriteReqEn);
			Bit#(${tpawidth}) a = w${modname}.brambus${index}ReqAddr();
		  ${iname}.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: a});			
		endrule 
    rule brambus${index}ReadRsp ( True ); 
      let _dd <- ${iname}.portB.response.get;
      w${modname}.brambus${index}ReadRsp(_dd);
    endrule
%endfor
//https://github.com/LEAP-Core/leap-examples/blob/master/modules/apps/examples/hls_mem_perf/leap_model/hls-core-bsv-wrapper.bsv
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
	NumTypeParam#(SizeOf#(${typename})) memDataSz${iname}${typename} = ?;
  mkHlsApBusMemConnection(${iname}, core.mbus${index},  memDataSz${iname}${typename}, True, ${index});
%endfor 

  //----------end support logic ------------------
  method Action start() if ((ks == IDLE) || (ks == FINISH));
    ks <= RUNNING;
  endmethod
  method Bool done() if (ks == FINISH);
   return True;
  endmethod
endmodule 
</%doc>
//module mk${modname}RAW(${state_containers_to_pass}, ${'I'+modname} ifc);
module mk${modname}(IDebugTrace dtlogger, ${state_containers_to_pass}, ${'I'+modname} ifc);
  Reg#(KState) ks <- mkReg(IDLE);
  //----------begin support logic ---------------
  let w${modname}Bundle <- mk${modname}_hls_bundles;
  let w${modname} = w${modname}Bundle.raw;
  
	%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
  let mbus${index} = w${modname}Bundle.mbus${index};
  %endfor 
  %for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
  FIFOF#(Tuple3#(Bit#(${tpawidth}), ${typename}, Bool)) reqFifo_mbus${index} <- mkSizedFIFOF(16);
  FIFOF#(${typename}) readRspFifo_mbus${index} <- mkSizedFIFOF(16);
  %endfor 
  
  %for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_mbus):
	// based on https://github.com/FelixWinterstein/LEAP-HLS/blob/master/merger/wrappers/bluespec/MyIP.bsv
	(* fire_when_enabled *)
	rule reqNotFull_mbus${index}(reqFifo_mbus${index}.notFull);
		mbus${index}.reqNotFull();
	endrule 
// 	(* fire_when_enabled *)
// 	rule rspNotEmpty_mbus${index}(readRspFifo_mbus${index}.notEmpty);
// 		mbus${index}.rspNotEmpty();
// 	endrule 
	// HLS IP generated writeReq (to external memory)
  (* fire_when_enabled *) 
	rule writeReq_mbus${index} ( mbus${index}.writeReqEn );
    Bit#(${tpawidth}) a = truncate(mbus${index}.reqAddr) ;
    ${typename} d = mbus${index}.writeData;
		reqFifo_mbus${index}.enq(tuple3(a,d,True));
    `ifdef MBUS_DEBUG_0
    dtlogger.debug($format("writeReq mbus${index} d=",fshow(d), " mbus${index}.reqAddr=", mbus${index}.reqAddr, " mbus${index}.reqSize=", mbus${index}.reqSize));
    `endif
	endrule
	rule memWriteReq_mbus${index} ( reqFifo_mbus${index}.notEmpty && tpl_3(reqFifo_mbus${index}.first()) );        
		match {.a, .d, .is_write} = reqFifo_mbus${index}.first();
		reqFifo_mbus${index}.deq;
    ${iname}.write(a, d);
    `ifdef MBUS_DEBUG_0
    dtlogger.debug($format("mbus${index} to ${iname}.write(a, d) a=",fshow(a), " d=", fshow(d)));
    `endif
	endrule
		
	// HLS IP generated readReq made on external memory
	(* fire_when_enabled *) 
	rule readReq_mbus${index} (!mbus${index}.writeReqEn);
    Bit#(${tpawidth}) a = mbus${index}.reqAddr  ;
		reqFifo_mbus${index}.enq(tuple3(truncate(a),?,False));
    `ifdef MBUS_DEBUG_0
    dtlogger.debug($format("mbus${index} submits readReq for mbus${index}.reqAddr=", mbus${index}.reqAddr, " mbus${index}.reqSize=", mbus${index}.reqSize));
    `endif
	endrule
	rule memReadReq_mbus${index} ( reqFifo_mbus${index}.notEmpty && !tpl_3(reqFifo_mbus${index}.first()) );        
		match {.a, .d, .is_write} = reqFifo_mbus${index}.first();
		reqFifo_mbus${index}.deq;
    ${iname}.readReq(a);  
    `ifdef MBUS_DEBUG_0
    dtlogger.debug($format("mbus${index} readReq sent to ${iname} for address=",fshow(a)));
    `endif
	endrule
	rule memReadRespFifo_mbus${index} (True);
    ${typename} resp <- ${iname}.readRsp();
		readRspFifo_mbus${index}.enq(resp);        
    `ifdef MBUS_DEBUG_0
    dtlogger.debug($format("${iname} responds with resp=",fshow(resp)));
    `endif
	endrule
	rule memReadResp_mbus${index} ( True ); // readRspFifo_mbus${index}.notEmpty ??
		mbus${index}.readRsp(readRspFifo_mbus${index}.first);
		readRspFifo_mbus${index}.deq;
    `ifdef MBUS_DEBUG_0
    dtlogger.debug($format("read response sent to mbus${index}"));
    `endif
	endrule

  %endfor 
  rule rstart(ks == RUNNING);
    w${modname}.start();
  endrule 
  rule rfinish(ks == RUNNING &&  w${modname}.isDone());
    ks <= FINISH;
  endrule 

  %for index,(typename,iname,vhlsportname) in enumerate(scs_1regs):
      rule set1reg${index}(ks == RUNNING); //warning
       w${modname}.set1reg${index}(${iname});
      endrule 
  %endfor 
  %for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_i):
      rule set1reg${index}(ks == RUNNING);
       w${modname}.set1reg${index}(${iname});
      endrule 
  %endfor 
  %for index,(typename,iname,vhlsportname) in enumerate(scs_1regs_o):
      rule get1reg${index}(ks == RUNNING);
       //w${modname}.set1reg${index}(${iname});
       ${iname} <= w${modname}.get1reg${index}();
      endrule 
  %endfor 
  %for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_ins):
      rule dataRegFileIn${index} (ks == RUNNING);
        let _aa <- w${modname}.getRegFileInAddress${index}();
        w${modname}.dataRegFileIn${index}(${iname}.sub(_aa));
      endrule 
  %endfor
  %for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_regfile_outs):
      rule dataRegFileOut${index}(ks == RUNNING);
        let _aa <- w${modname}.getRegFileOutAddress${index}();
        ${iname}.upd(_aa, w${modname}.dataRegFileOut${index}());
      endrule 
  %endfor

%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_i):
      rule dataBramApMemIn${index} (ks == RUNNING);
        let _aa <- w${modname}.getBramApMemInAddress${index}();
       // w${modname}.dataBramApMemIn${index}(${iname}.sub(_aa));
       ${iname}.portB.request.put(BRAMRequest{write:False,responseOnWrite:False,address:_aa});
      endrule 
      rule dataBramApMemIn${index}Get (ks == RUNNING);
        let _dd<-${iname}.portB.response.get;
        w${modname}.dataBramApMemIn${index}(_dd);
      endrule
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_o):
      rule dataBramApMemOut${index}(ks == RUNNING);
        let _aa <- w${modname}.getBramApMemOutAddress${index}();
        //${iname}.upd(a, w${modname}.dataBramApMemOut${index}());
        ${iname}.portB.request.put(BRAMRequest{write:True,responseOnWrite:False,address:_aa,datain:w${modname}.dataBramApMemOut${index}()});
      endrule 
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory_io):
   // RULES NOT IMPLEMENTED YET
      rule dataBramApMemIn_io_${index} (ks == RUNNING);
      let _aa <- w${modname}.getBramApMemInAddress_io_${index}();
       // w${modname}.dataBramApMemIn${index}(${iname}.sub(a));
       ${iname}.portB.request.put(BRAMRequest{write:False,responseOnWrite:False,address:_aa});
      endrule 
      rule dataBramApMemIn_io_${index}Get (ks == RUNNING);
      let _dd<-${iname}.portB.response.get;
        w${modname}.dataBramApMemIn_io_${index}(_dd);
      endrule
      rule dataBramApMemOut$_io_${index}(ks == RUNNING);
        let _aa <- w${modname}.getBramApMemOutAddress_io_${index}();
        //${iname}.upd(a, w${modname}.dataBramApMemOut${index}());
        ${iname}.portB.request.put(BRAMRequest{write:True,responseOnWrite:False,address:_aa,datain:w${modname}.dataBramApMemOut_io_${index}()});
      endrule 
      
%endfor


%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_i):
      rule dataramApMemIn${index} (ks == RUNNING);
      let _aa <- w${modname}.getramApMemInAddress${index}();
       ${iname}.readReq(_aa);
      endrule 
      rule dataramApMemIn${index}Get (ks == RUNNING);
        let _dd<-${iname}.readRsp();
        w${modname}.dataramApMemIn${index}(_dd);
      endrule
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_o):
      rule dataramApMemOut${index}(ks == RUNNING);
        let _aa <- w${modname}.getramApMemOutAddress${index}();
        ${iname}.write(_aa, w${modname}.dataramApMemOut${index}());
      endrule 
%endfor
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_ram_ap_memory_io):
      rule dataramApMemIn_io_${index} (ks == RUNNING);
        let _aa <- w${modname}.getramApMemInAddress_io_${index}();
        ${iname}.readReq(_aa); 
      endrule 
      rule dataramApMemIn_io_${index}Get (ks == RUNNING);
      let _dd<-${iname}.readRsp();
      w${modname}.dataramApMemIn_io_${index}(_dd);
      endrule
      rule dataramApMemOut$_io_${index}(ks == RUNNING);
        let _aa <- w${modname}.getramApMemOutAddress_io_${index}();
        ${iname}.write(_aa, w${modname}.dataramApMemOut_io_${index}());
      endrule 

%endfor


%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bram_ap_memory):
      rule dataBramApMemIn${index} (ks == RUNNING);
        let _aa <- w${modname}.getBramApMemInAddress${index}();
       // w${modname}.dataBramApMemIn${index}(${iname}.sub(a));
       ${iname}.portB.request.put(BRAMRequest{write:False,responseOnWrite:False,address:_aa});
      endrule 
      rule dataBramApMemIn${index}Get (ks == RUNNING);
      let _dd<-${iname}.portB.response.get;
        w${modname}.dataBramApMemIn${index}(_dd);
      endrule
      rule dataBramApMemOut${index}(ks == RUNNING);
        let _aa <- w${modname}.getBramApMemOutAddress${index}();
        //${iname}.upd(a, w${modname}.dataBramApMemOut${index}());
        ${iname}.portB.request.put(BRAMRequest{write:True,responseOnWrite:False,address:_aa,datain:w${modname}.dataBramApMemOut${index}()});
      endrule 
%endfor

##(* fire_when_enabled *)
##rule enDataIn0(ks == RUNNING && p.notEmpty);
##  w${modname}.enDataIn0();
##endrule 
##(* fire_when_enabled *)
##rule enDataOut0(ks == RUNNING && r.notFull);
##  w${modname}.enDataOut0();
##endrule 
%for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_ins):
    //(* fire_when_enabled *)
    rule enDataIn${index}(ks == RUNNING && ${iname}.notEmpty);
      w${modname}.enDataIn${index}();
    endrule 
    
    rule data_in${index}(True);
      w${modname}.data_in${index}(${iname}.first); ${iname}.deq;
    endrule 
%endfor    
%for index,(typename,iname,vhlsportname) in enumerate(scs_fifof_outs):
    //(* fire_when_enabled *)
    rule enDataOut${index}(ks == RUNNING && ${iname}.notFull);
      w${modname}.enDataOut${index}();
    endrule 
    //(* fire_when_enabled *)
    rule data_out${index}(True);
    let d = w${modname}.data_out${index}(); ${iname}.enq(d);
    endrule 
%endfor    

##rule data_in${index}(True);
##  w${modname}.data_in${index}(p.first); p.deq;
##endrule 
##
##(* fire_when_enabled *)
##rule data_out0(True);
##  let d = w${modname}.data_out0(); r.enq(d);
##endrule 
%for index,(typename,iname,vhlsportname,tpawidth) in enumerate(scs_bus_bram):
 //   (* fire_when_enabled *)
    rule brambus${index}WriteReq ( w${modname}.brambus${index}WriteReqEn );

        Bit#(${tpawidth}) a = w${modname}.brambus${index}ReqAddr();
        ${typename} d = w${modname}.brambus${index}WriteData;
        //reqFifo.enq(tuple3(a,d,True));
				${iname}.portB.request.put(BRAMRequest{write: True, responseOnWrite: False, address: a, datain: d});
    endrule
 //   (* fire_when_enabled *)
    rule brambus${index}ReadReq(!w${modname}.brambus${index}WriteReqEn);
			Bit#(${tpawidth}) a = w${modname}.brambus${index}ReqAddr();
		  ${iname}.portB.request.put(BRAMRequest{write: False, responseOnWrite: False, address: a});			
		endrule 
    rule brambus${index}ReadRsp ( True ); 
				let d <- ${iname}.portB.response.get;
        w${modname}.brambus${index}ReadRsp(d);
    endrule

%endfor
  //----------end support logic ------------------
  method Action start() if ((ks == IDLE) || (ks == FINISH));
    ks <= RUNNING;
  endmethod
  method Bool done() if (ks == FINISH);
   return True;
  endmethod
endmodule 


## vim: ft=mako
