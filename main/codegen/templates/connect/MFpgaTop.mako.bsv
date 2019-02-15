<%include file='Banner.mako' args="_am=_am"/>
<%
  flit_sr_ports_tid_all = [tid for tid, tname, tqual in _am.get_tasks_marked_for_exposing_flit_SR_ports()]
  flit_sr_ports_tname_all = [tname for tid, tname, tqual in _am.get_tasks_marked_for_exposing_flit_SR_ports()]
%>
package MFpgaTop;

## EMIT IMPORTPACKAGES ===================================================
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
  import InterFPGA::*;
%endif

%for partname, _ in _am.task_partition_map.items():
  import Top_${partname}::*;
%endfor 
import Clocks::*;

interface MFpgaTop;
%for id in flit_sr_ports_tid_all:
  interface Put#(Flit) putFlit${id};
  interface Get#(Flit) getFlit${id};
%endfor 
endinterface 

(* synthesize *)
module [Module] mkMFpgaTop(MFpgaTop);
  let clk <- exposeCurrentClock();
  let rst <- exposeCurrentReset();
%for partname, part_tmap in _am.task_partition_map.items():
  <%
    quasiserdes_sr_ports_tid_list = [tid for tid, tname, tqual in _am.get_tasks_marked_for_exposing_quasiserdes_sr_ports() if tid in part_tmap.values()]
  %>
  // clocks: ${['clkinX{0}, rstinX{0}'.format(tid) for tid in quasiserdes_sr_ports_tid_list]}
  let x${partname} <- mkTop_${partname}(${", ".join(['clk, rst']*len(quasiserdes_sr_ports_tid_list))});
%endfor 
%for fromfpga, fromnode, tofpga, tonode in _am.interfpga_links:
  // linking ports between ${fromfpga} <--> ${tofpga}
  mkConnection(x${fromfpga}.deq_serial${fromnode}, x${tofpga}.enq_serial${tonode});
  mkConnection(x${tofpga}.deq_serial${tonode}, x${fromfpga}.enq_serial${fromnode});
%endfor 
%for id, tname in zip(flit_sr_ports_tid_all, flit_sr_ports_tname_all):
  %for partname, part_tmap in _am.task_partition_map.items():
    %if tname in part_tmap: 
    interface putFlit${id} = x${partname}.putFlit${id};
    interface getFlit${id} = x${partname}.getFlit${id};
    %endif 
  %endfor 
%endfor 
##mkConnection(xfpga1.deq_serial0, xfpga2.enq_serial0);
##mkConnection(xfpga2.deq_serial0, xfpga1.enq_serial0);
endmodule 
endpackage
## vim: ft=mako
