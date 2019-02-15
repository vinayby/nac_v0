<%include file='Banner.mako' args="_am=_am"/>
<%!
  import pdb
  import os
%>\
package Tasks;
  import NTypes::*;
  import NATypes::*;
  import CnctBridge::*;
  import FIFO::*;
  import FIFOF::*;
  import BRAM::*;
  import Connectable::*;
  import GetPut::*;
  import Vector::*;
  import StmtFSM::*;
  import Assert::*;
  import DefaultValue::*;
  import RegFile::*;
  import Fifo_merge::*;
  import DebugTrace::*;
%if _am.has_scs_type('__ram__') or _am.has_scs_type('__mbus__'):
  import Memory_interface::*;
  import LeapBram::*;
%endif
  %for k in _hwkernels:
  import ${k}::*;
  %endfor 
 `define SYNCDEBUG
%if _am.args.simverbosity == 'state-exit':
 `define DEBUGPRINTS1
%endif 
%if _am.args.simverbosity == 'state-entry-exit':
 `define DEBUGPRINTS0
 `define DEBUGPRINTS1
%endif 
%if _am.args.simverbosity == 'to-from-network':
  // `define DEBUGPRINTS2 // prints packets sent ToNetwork 
 `define DEBUGPRINTS3  // flits to from network
%endif
%if _am.args.simverbosity == 'send-recv-trace':
 `define INSTRUMENT_PRINTS
%endif
##
## pass-1
## TODO: for instances 'more than 1', if-endif skip
<% 
already_generated = dict()
%>
%for k in range(0, len(_am.tmodels)): 
 <% 
 _tm = _am.tmodels[k]
 _task_name = 'Task_'+ _tm.taskname
 %>
 %if not _tm.is_marked_off_chip or (_tm.is_marked_off_chip and _am.enabled_lateral_data_io):
     %if _tm.taskdefname not in already_generated:
       
   %if _am.args.new_tofrom_network:
    <%include file='ToNetwork1.mako.bsv' args="_am=_am,_tm=_tm"/>
    <%include file='FromNetwork1.mako.bsv' args="_am=_am,_tm=_tm"/>
   %else:
    <%include file='ToNetwork.mako.bsv' args="_am=_am,_tm=_tm"/>
    <%include file='FromNetwork.mako.bsv' args="_am=_am,_tm=_tm"/>
   %endif  
    %if (_tm.is_marked_off_chip and _am.enabled_lateral_data_io):
      <%include file='TaskCoreLatIO.mako.bsv' args="_am=_am,_tm=_tm"/>
    %else:
      <%include file='TaskCore.mako.bsv' args="_am=_am,_tm=_tm"/>
    %endif 
    <% 
    already_generated[_tm.taskdefname] = True 
    %>
    %endif
  %endif 
  %if not _tm.is_task_instance():
    <%include file='TaskNode.mako.bsv' args="_am=_am,_tm=_tm"/>
  %endif
%endfor ### pass-1
//XX task defs andn virtual tasks generated
##
## pass-2
##
%for k in range(0, len(_am.tmodels)): 
 <% 
 _tm = _am.tmodels[k]
 _task_name = 'Task_'+ _tm.taskname
 %>
 %if _tm.is_task_instance():

  <%include file='TaskNode.mako.bsv' args="_am=_am,_tm=_tm"/>

 %endif ## ENDIF is_task_instance()
%endfor ### pass-2

<%doc> Do this via tmodels for now 
##
## InterFPGA Link nodes
## 
%for ifln in _am.interfpg_link_nodes:
module mkNode${ifln.['name']}#(parameter PortId portid)(NOCPort);
let bridge <- mkCnctBridge();
%if _am.noc_uses_credit_based_flowcontrol():
	method getFlit = bridge.nocPort.getFlit;
	method putCredits = bridge.nocPort.putCredits;
	method setRecvFlit = bridge.nocPort.setRecvFlit;
	method getCredits = bridge.nocPort.getCredits;
	method setRecvPortID = bridge.nocPort.setRecvPortID;
%else:
	method getFlit = bridge.nocPort.getFlit;
	method setNonFullVC = bridge.nocPort.setNonFullVC;
	method setRecvFlit = bridge.nocPort.setRecvFlit;
	method getRecvVCMask = bridge.nocPort.getRecvVCMask;
	method setRecvPortID = bridge.nocPort.setRecvPortID;
%endif\

%if _tm.is_marked_off_chip:
	interface putFlitSoft = bridge.nocPort.putFlitSoft;
  interface getFlitSoft = bridge.nocPort.getFlitSoft;
  // essentially:
  // return bridge.nocPort;
%endif
endmodule 
%endfor 
</%doc>
endpackage
## vim: ft=mako



