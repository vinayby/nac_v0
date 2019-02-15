<%include file='Banner.mako' args="om=om"/>
package Top;
import NATypes::*;
import CnctBridge::*;
import Tasks::*;
import Connectable::*;
import Vector::*;
%if om.noc_uses_credit_based_flowcontrol():
import Network::*;
%else:
import NetworkSimple::*;
%endif
import GetPut::*;
import FIFO::*;

%if om.has_off_chip_nodes():
\
interface TOP;\
%if len(om.get_off_chip_node_id_list()) == 1:
  <%
  lone_off_chip_tid, lone_off_chip_tname = om.get_off_chip_node_id_list()[0]
  %>
  interface Put#(Flit) putFlit;
  interface Get#(Flit) getFlit;
%else:
   TODO: offchip, scemi|eth --to-- getFlit_scemi|eth
%endif
endinterface

(* synthesize *)   
module [Module] mkTop(TOP); 

%else: ## no nodes marked as off_chip

(* synthesize *)   
module [Module] mkTop(); 
%endif
	Vector#(NUM_NODES, NOCPort) nodes = newVector;
  
%for k in range(0, len(om.tm_list)):
  <%
    _tm = om.tm_list[k]
    _pe_name = 'Task_'+ _tm.get_task_name()
  %>\
  nodes[${_tm.mapped_to_node}] <- mkNode${_pe_name}(${_tm.mapped_to_node});
%endfor

%if om.noc_uses_credit_based_flowcontrol():
  NetworkIfc noc <- mkNetwork;
%else:
  NetworkSimpleIfc noc <- mkNetworkSimple;
%endif
<%
  
%>\
for(Integer i=0; i<valueOf(NUM_NODES); i=i+1) begin
  // prevent activation of unused node interface methods
  if(${'||'.join(map(lambda x: 'i == '+str(x), [tm.mapped_to_node for tm in om.tm_list]))}) begin 
    mkConnection(nodes[i].getFlit, noc.send_ports[i].putFlit);
  %if om.noc_uses_credit_based_flowcontrol(): ##---------------if
    mkConnection(noc.send_ports[i].getCredits, nodes[i].putCredits);
    mkConnection(nodes[i].getCredits, noc.recv_ports[i].putCredits);
  %else:                                      ##---------------
    mkConnection(noc.send_ports[i].getNonFullVCs, nodes[i].setNonFullVC);
    mkConnection(nodes[i].getRecvVCMask, noc.recv_ports[i].putNonFullVCs);
  %endif                                      ##----------------endif 
    mkConnection(noc.recv_ports[i].getFlit, nodes[i].setRecvFlit);
    mkConnection(noc.recv_ports_info[i].getRecvPortID, nodes[i].setRecvPortID);
  end 
end

%if om.has_off_chip_nodes():
interface putFlit = nodes[${lone_off_chip_tid}].putFlitSoft; // ${lone_off_chip_tname}
interface getFlit = nodes[${lone_off_chip_tid}].getFlitSoft;
%endif
endmodule
endpackage
## vim: ft=mako
