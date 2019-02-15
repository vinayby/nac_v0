package Tb;
import NTypes::*;
import GetPut::*;
import Clocks::*;
%if _am.has_tasks_marked_for_xfpga:
import MFpgaTop::*;
%else:
import Top::*;
%endif
<%
flit_sr_ports_all = [tid for tid, tname, tqual in _am.get_tasks_marked_for_exposing_flit_SR_ports()]
%>
module mkTb();
  let clk <- exposeCurrentClock();
%if _am.has_tasks_marked_for_xfpga:
  let top <- mkMFpgaTop();
  Reg#(int) state <- mkReg(0);
%else:
  let top <- mkTop();
%endif
%if _am.has_off_chip_nodes():
	Reg#(int) counter <- mkReg(0);
	Reg#(DestAddr) destAddr <- mkReg(1);
  rule ticktock; counter <= counter + 1; endrule 
  %for id in flit_sr_ports_all:
    rule recv${id};
    Flit f <- top.getFlit${id}.get();
    $display("PORT${id} ", fshow(f), " at cc=%d", counter);
    endrule 
  %endfor 
%endif
endmodule

endpackage
## vim: ft=mako
