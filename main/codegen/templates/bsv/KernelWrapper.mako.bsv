<%! from time import strftime as time %>
<% 
import pdb
ziplist = pedecl.ziplist
%>\
// 
##// Kernel PE Wrapper Generated at ${time('%Y/%m/%d %H:')}
// Can FILL-IN the details in BSV (it won't be overwritten on re-run)
//   
%if '__vivadohls__' == pedecl.tq:
  <%include file="HLSKernelWrapper.mako.bsv" args="_am=_am,modname=modname, pedecl=pedecl"/>
%else:
  ##
  ## regular bsv pe wrappers
  ##
import DefaultValue::*;
import NATypes::*;
import RegFile::*;

import FIFO::*;
import FIFOF::*;
import BRAM::*;
import Connectable::*;
import GetPut::*;
import Vector::*;

`ifdef 0
import FPDef::*;
import FPUModel::*;
import FPUWrap::*;
`endif

interface ${'I'+modname};
  method Action start();
  method Bool done();
endinterface

<%
  import math
  sc2pass=[]
  moreinfo = ', '.join([repr((i, z)) for s,i,z,x in ziplist])
  for s, i, z, _scs in ziplist:
    scdecl=''
    if i[0] == '&':
      i=i[1:]
    if not _scs or _scs == '__fifo__':  # default FIFOF
      scdecl="FIFOF#("+s+") "+i;
    elif _scs == '__bram__':
      scdecl="BRAM2Port#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
    elif _scs == '__mbus__':
      scdecl="MEMORY_IFC#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
    elif _scs == '__ram__':
      scdecl="MEMORY_IFC#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
    elif _scs == '__reg__':
      if z == 1:
        scdecl="Reg#("+s+") "+i;
      else:
        scdecl="RegFile#(Bit#("+str(int(math.ceil(math.log(z, 2))))+"), "+s+") "+i;
    sc2pass.append(scdecl) 
  state_containers_to_pass =  ', '.join(sc2pass)
%>\
//${moreinfo}
%if not state_containers_to_pass:
  (* synthesize *)
%endif\  
module mk${modname}(${state_containers_to_pass}, ${'I'+modname} ifc);
  Reg#(KState) ks <- mkReg(IDLE);
  //----------begin support logic ---------------
    // rule r1 (ks == RUNNING);
    // endrule 
    // rule r_last( ks == RUNNING);
    // ....
    // ks <= FINISH;
    // endrule 
  //----------end support logic ------------------
  method Action start() if ((ks == IDLE) || (ks == FINISH));
    ks <= RUNNING;
  endmethod
  method Bool done() if (ks == FINISH);
   return True;
  endmethod
endmodule
%endif
## vim: ft=mako
