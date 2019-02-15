package Tb;
import NATypes::*;
import GetPut::*;
import Top::*;

module mkTb();
  let top <- mkTop();
%if om.has_off_chip_nodes():
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

