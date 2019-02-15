package KernelLib;
  import NATypes::*;
  import CnctBridge::*;
  import FIFO::*;
  import FIFOF::*;
  import Connectable::*;
  import GetPut::*;
  import Vector::*;
  <%
    import os
   %>
%for k in range(0, len(om.tm_list)): ## FOR1 TOP iteration over all tasks
 <% 
 _tm = om.tm_list[k]
 _task_name = 'Task_'+ _tm.get_task_name()
 %>
%for pepath in _tm.get_kernel_pe_paths():
`ifndef ${os.path.basename(pepath).upper()[0:-4]}_BSV
`define ${os.path.basename(pepath).upper()[0:-4]}_BSV
`include "${pepath}"
`endif
%endfor 

%endfor

endpackage

