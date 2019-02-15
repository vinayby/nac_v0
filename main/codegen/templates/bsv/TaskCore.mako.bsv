
<%page args="_tm,_am"/>\
 <% 
 #_task_name = 'Task_'+ _tm.taskname
 _task_name = 'Task_'+ _tm.taskdefname
 incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
 outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]
 modparams=[]
 # get task type params
 tasktype_params = _tm.get_taskdef_parameters('task')
 modparams.extend(['DestAddr '+task for task in tasktype_params])
 # get string type params 
 stringtype_params = _tm.get_taskdef_parameters('string')
 modparams.extend(['String '+s for s in stringtype_params])


 # get other type params 
 modparams = ['DestAddr node_id', 'String snode_id', 'String task_instance_name'] + modparams
 modparams_string = ', '.join(modparams)
 %>
 
 interface ${_task_name};
##%if incoming_types:
##  interface Vector#(${len(_tm.get_unique_message_sources())}, Put#(ReceptionUnion${_task_name}_tuple)) putPacket;
##%endif 
%if outgoing_types:
  interface Get#(DispatchUnion${_task_name}_tuple) getPacket;		
%endif 
//interface Put#(Flit) putSyncMsg;
//interface Vector#(${len(_am.tmodels)}, Put#(Flit)) putSyncMsg;
//interface Get#(Flit) getSyncMsg;
endinterface

 
%if _tm.is_task_instance():
  module mk${_task_name}(
%if outgoing_types:
  FIFO#(DispatchUnion${_task_name}_tuple) outFifo, 
%endif
%if incoming_types:
  Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_task_name}_tuple)) inFifo,
%endif
  Vector#(${len(_am.tmodels)}, FIFO#(Flit)) cmsgfifo_in,
  MERGE_FIFOF#(${len(_am.tmodels)}, Flit) cmsgfifo_out,
  ${modparams_string}, ${_task_name} ifc);
%else:
//(* synthesize *) 
module mk${_task_name}(
%if outgoing_types:
  FIFO#(DispatchUnion${_task_name}_tuple) outFifo, 
%endif
%if incoming_types:
  Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_task_name}_tuple)) inFifo,
%endif
  Vector#(${len(_am.tmodels)}, FIFO#(Flit)) cmsgfifo_in,
  MERGE_FIFOF#(${len(_am.tmodels)}, Flit) cmsgfifo_out,
          ${_task_name} ifc);
DestAddr node_id = ${_tm.mapped_to_node};
String snode_id = "${_tm.mapped_to_node}";
%endif
//FIFO#(Flit) cmsgfifo_in <- mkFIFO;
//Vector#(${len(_am.tmodels)}, FIFOF#(Flit)) cmsgfifo_in  <- replicateM(mkFIFOF());
//MERGE_FIFOF#(${len(_am.tmodels)}, Flit) cmsgfifo_out <- mkMergeFIFOF;
  Reg#(SourceAddr) saved_source_address <- mkRegU;
  //  Reg#(int) cticks <- mkReg(0); //local
%if incoming_types:
  MERGE_FIFOF#(${len(_tm.get_unique_message_sources())}, ReceptionUnion${_task_name}_tuple) mergeF  <- mkMergeFIFOF; // TODO perhaps use only when have multiple_sources on any recv stmt
%endif
%if _tm.iff_use_mergefifo:
  MERGE_FIFOF#(${len(_am.tmodels)}, Flit) mergeF_cmsg_in  <- mkMergeFIFOF; // TODO perhaps use only when have multiple_sources on any recv stmt
%endif 
//rule ticktock;
//  cticks <= cticks + 1;
//endrule 
%if _tm.iff_use_mergefifo:
  for(Integer j=0; j<${len(_tm.get_unique_message_sources())}; j=j+1) begin
  rule infifo2mergeF;
  inFifo[j].deq; mergeF.ports[j].enq(inFifo[j].first);
  endrule 
  end 
  for(Integer j=0; j<${len(_am.tmodels)}; j=j+1) begin
  rule incmsg2mergeF;
  cmsgfifo_in[j].deq; mergeF_cmsg_in.ports[j].enq(cmsgfifo_in[j].first);
  endrule 
  end 
%endif 

##  %if incoming_types:
##FIFOF#(ReceptionUnion${_task_name}_t2) inFifoAny <- mkFIFOF;
##Reg#(Bool) enableinFifoAny <- mkReg(False);
##for(Integer i=0; i<${len(_tm.get_unique_message_sources())}; i=i+1) begin
##  rule many2one (enableinFifoAny);
##    inFifoAny.enq(inFifo[i].first); inFifo[i].deq;
##  endrule 
##  end //for
##%endif 
 
  <%include file='PEBody.mako.bsv' args="_am=_am,_tm=_tm,_task_name=_task_name,type_table=_am.type_table"/>

  Vector#(${len(_am.tmodels)}, Put#(Flit)) putSyncMsgV  = newVector;

  for(Integer j=0; j<${len(_am.tmodels)}; j=j+1) begin
  putSyncMsgV[j] = toPut(cmsgfifo_in[j]); end
  
##  %if incoming_types:
##  Vector#(${len(_tm.get_unique_message_sources())}, Put#(ReceptionUnion${_task_name}_tuple)) putPacketV  = newVector;
##  for(Integer j=0; j<${len(_tm.get_unique_message_sources())}; j=j+1) begin
##  %if not _tm.iff_use_mergefifo:
##    putPacketV[j] = toPut(inFifo[j]);
##  %else:
##      putPacketV[j] = toPut(mergeF.ports[j]);
##  %endif
##  end 
## interface putPacket = putPacketV;  
## %endif
%if outgoing_types:
  interface getPacket = toGet(outFifo);
%endif 

  //interface putSyncMsg = toPut(cmsgfifo_in);
  //interface putSyncMsg = putSyncMsgV;
  //interface getSyncMsg = toGet(cmsgfifo_out);
endmodule //mk${_task_name}


##################################################################################################
##################################################################################################
## vim: ft=mako
