##=================================================================================================                                                                         
##  EMIT IMPORTPACKAGES
##    
##  EMIT Top INTERFACE
##    if has NUM_FLIT_SR_PORTS number of flit-level send-recv ports
##      - (getFlit, putFlit)[NUM_FLIT_SR_PORTS]
##      if has NUM_INTERFPGA_SR_PORTS number of Quasi-Serial send-recv ports
##      - (deq_serial,enqserial)[NUM_INTERFPGA_SR_PORTS]
##    
##  EMIT mkTop MODULE BODY
##=================================================================================================                                                                         
<%include file='Banner.mako' args="_am=_am"/>
##=================================================================================================                                                                         
## PREPARATION 
##=================================================================================================                                                                         
<%
  import pdb 
  top_name = "Top"
  is_an_fpga_partition = False 
  
  tmap = _am.global_task_map
  if _partname:
    tmap = _am.task_partition_map[_partname]
  # it could be partitioned, yet not for mFPGA
  if _partname and _am.has_tasks_marked_for_xfpga:
    is_an_fpga_partition = True
  
  if is_an_fpga_partition:
    top_name += '_' + _partname 

  # collect tid's in this partition
  flit_sr_ports_tid_list        = [tid for tid, tname, tqual in _am.get_tasks_marked_for_exposing_flit_SR_ports() if tname in tmap]
  quasiserdes_sr_ports_tid_list = [tid for tid, tname, tqual in _am.get_tasks_marked_for_exposing_quasiserdes_sr_ports() if tname in tmap]
  quasiserdes_sr_ports_clocknames = ["Clock clkinX{0}, Reset rstinX{0}".format(tid) for tid in quasiserdes_sr_ports_tid_list]

  top_module_formalArguments = quasiserdes_sr_ports_clocknames 
  local_tmodels = [t for t in _am.tmodels if t.taskname in tmap]
%>
package ${top_name};

##=================================================================================================                                                                         
## IMPORTPACKAGES 
##=================================================================================================                                                                         
import NTypes::*;
import CnctBridge::*;
import Tasks::*;
import Connectable::*;
import Vector::*;

%if _am.psn.is_connect_credit():
import Network::*;

%elif _am.psn.is_connect_peek():
import NetworkSimple::*;

%endif 

import GetPut::*;
import FIFO::*;

%if _am.psn.is_fnoc():
  import ForthRouter::*;
  import topology::*;
%endif

%if is_an_fpga_partition:
  import InterFPGA_LVDS::*;
%endif

##=================================================================================================
## TOP INTERFACE 
##=================================================================================================
interface I${top_name};
%for id in flit_sr_ports_tid_list:
  interface Put#(Flit) putFlit${id};
  interface Get#(Flit) getFlit${id};
  %if _am.enabled_lateral_data_io:
  interface Put#(NARawData) putRawData${id};
  interface Get#(NARawData) getRawData${id};
  %endif 
%endfor 

%for id in quasiserdes_sr_ports_tid_list:
  interface Get#(Bit#(LVDS_DW)) deq_serial${id};
  interface Put#(Bit#(LVDS_DW)) enq_serial${id}; 
%endfor 
endinterface 
##=================================================================================================
## SUPPORT DEF BLOCKS 
##=================================================================================================
<%def name="make_node_network_connections()">
  mkConnection(nodes[i].nocPort.getFlit, noc.send_ports[i].putFlit);
  mkConnection(noc.recv_ports[i].getFlit, nodes[i].nocPort.setRecvFlit);
%if _am.psn.is_connect_credit():
  mkConnection(noc.send_ports[i].getCredits, nodes[i].nocPort.putCredits);
  mkConnection(nodes[i].nocPort.getCredits, noc.recv_ports[i].putCredits);

%elif _am.psn.is_connect_peek() or _am.psn.is_fnoc_peek():
  mkConnection(noc.send_ports[i].getNonFullVCs, nodes[i].nocPort.setNonFullVC);
  mkConnection(nodes[i].nocPort.getRecvVCMask, noc.recv_ports[i].putNonFullVCs);

%endif

%if _am.psn.is_fnoc():
//  mkConnection(noc.recv_ports_info[i].getRecvPortID, nodes[i].setRecvPortID);
%endif
</%def>


<%def name="top_module_arguments_csv()">
  %if top_module_formalArguments:
    ${', '.join(top_module_formalArguments)}, I${top_name} ifc
  %else:
    I${top_name}
  %endif 
</%def>

##=================================================================================================                                                                         
## MODULE BODY 
##=================================================================================================                                                                         
(* synthesize *)
module [Module] mk${top_name}(${top_module_arguments_csv()});

  Vector#(NUM_NODES, NodePort) nodes = newVector;
 %for id in quasiserdes_sr_ports_tid_list:
   let xfpga${id} <- mkInterFPGA_LVDS(${id}, clkinX${id}, rstinX${id}); 
 %endfor 

 %for _tm in local_tmodels:
   nodes[${_tm.mapped_to_node}] <- mkNode${'Task_'+_tm.taskname}(${_tm.mapped_to_node});
 %endfor 
 
 let noc <- ${_am.psn.get_mkTopName()};

for(Integer i=0; i<valueOf(NUM_NODES); i=i+1) begin
  // prevent activation of unused node interface methods
 if(${'||'.join(map(lambda x: 'i=={}'.format(x), [t.mapped_to_node for t in local_tmodels]))}) begin
  
  ${make_node_network_connections()}

 end // if 
end // for 
 
%for tid in quasiserdes_sr_ports_tid_list:
  mkConnection(nodes[${tid}].lateralIO.getFlit, xfpga${tid}.tx);
  mkConnection(xfpga${tid}.rx, nodes[${tid}].lateralIO.putFlit);
%endfor 


// interface setups 
%for id in flit_sr_ports_tid_list:
  interface putFlit${id} = nodes[${id}].lateralIO.putFlit; 
  interface getFlit${id} = nodes[${id}].lateralIO.getFlit; 
%endfor 

// bulk IO setup
  %if _am.enabled_lateral_data_io:
%for id in flit_sr_ports_tid_list:
  interface putRawData${id} = nodes[${id}].lateralIO.putRawData; 
  interface getRawData${id} = nodes[${id}].lateralIO.getRawData; 
%endfor 
  %endif 

%for id in quasiserdes_sr_ports_tid_list:
  interface deq_serial${id} =  xfpga${id}.deq_serial;
  interface enq_serial${id} =  xfpga${id}.enq_serial;
%endfor

endmodule 
endpackage
##=================================================================================================                                                                         
##=================================================================================================                                                                         
## vim: ft=mako


