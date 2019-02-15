package Tb;
import NTypes::*;
import GetPut::*;
import Clocks::*;
%if _am.has_tasks_marked_for_xfpga:
import MFpgaTop::*;
%else:
import Top::*;
%endif

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
  rule ticktock;
    counter <= counter + 1;
  endrule 
	rule recv0; // result
		Flit f <- top.getFlit.get(); 
    $display(fshow(f), " at cc=%d", counter);
	endrule
%endif
endmodule

endpackage

