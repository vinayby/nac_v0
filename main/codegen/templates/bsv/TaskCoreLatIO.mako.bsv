
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
endinterface

 
%if _tm.is_task_instance():
  module mk${_task_name}(

  %if outgoing_types:
    FIFO#(DispatchUnion${_task_name}_tuple) outFifo, 

  %endif
  
  %if incoming_types:
    Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_task_name}_tuple)) inFifo,

  %endif
  
  GetPut#(NARawData) raw_in, GetPut#(NARawData) raw_out, ${modparams_string}, ${_task_name} ifc);


%else:
//(* synthesize *) 
  module mk${_task_name}(
  
  %if outgoing_types:
    FIFO#(DispatchUnion${_task_name}_tuple) outFifo, 
  %endif
  
  %if incoming_types:
    Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_task_name}_tuple)) inFifo,
  %endif
  
  GetPut#(NARawData) raw_in, GetPut#(NARawData) raw_out , ${_task_name} ifc);

  DestAddr node_id = ${_tm.mapped_to_node};
  String snode_id = "${_tm.mapped_to_node}";

%endif
%if incoming_types:
  MERGE_FIFOF#(${len(_tm.get_unique_message_sources())}, ReceptionUnion${_task_name}_tuple) mergeF  <- mkMergeFIFOF; // TODO perhaps use only when have multiple_sources on any recv stmt
%endif

## %if _tm.iff_use_mergefifo:
  for(Integer j=0; j<${len(_tm.get_unique_message_sources())}; j=j+1) begin
  rule infifo2mergeF;
  inFifo[j].deq; mergeF.ports[j].enq(inFifo[j].first);
  endrule 
  end 
## %endif 

FIFO#(NARawData) tmp_loop_pipe <- mkFIFO;
//String task_instance_name = "${_tm.taskname}";
// mkConnection(tpl_1(raw_in) /* Get */,  tpl_2(raw_out) /* Put */);

rule fromlatIO_toNetwork;
   let d <- tpl_1(raw_in).get();
   FlitHeaderPayLoad hf;
   hf.srcaddr = unpack(truncate(d.address)); 
   hf.ttag = pack(truncate(d.typetag));
   let utype = taggedTypeOut${_task_name}(hf, 0, unpack(0));
   //tmp_loop_pipe.enq(d);
   $display("in tonetwork: ", fshow(d), " taggedType = ", fshow(utype));
   //outFifo.enq(tuple4(address, tagged TTypeName sendobj_val, out_vc, opts));
   match {.dstaddr, .taggedtype, .out_vc, .opts} =  utype;
   // assuming d.nelems_packed is 1
   %if outgoing_types:
   case (taggedtype) matches
     ##----------------------------------------------
     %for t in outgoing_types:
       tagged T${t} .obj: begin 
         // assuming d.nelems_packed == 1
         ${t} upd = unpack(truncate(pack(d.data)));
         // taggedtype = tagged T${t} upd; // bsv error: Constructor `TT1' is not disambiguated by type
          outFifo.enq(tuple4(dstaddr, tagged T${t} upd, out_vc, opts));
        end 
      %endfor 
    endcase 
   %endif
     ##----------------------------------------------
endrule 

rule fromNetwork_tolatIO;
NARawData d = unpack(0);
  let dn = mergeF.first; mergeF.deq;
  match {.srcaddr, .taggedtype, .opts} = dn;
  d.address = unpack(zeroExtend(pack(srcaddr)));
  d.typetag = 0;
   // assuming d.nelems_packed is 1
   %if incoming_types:
   case (taggedtype) matches
     ##----------------------------------------------
     %for t in incoming_types:
       tagged T${t} .obj: begin 
         // assuming d.nelems_packed == 1
         d.data = zeroExtend(pack(obj));
       end 
      %endfor 
    endcase 
   %endif
     ##----------------------------------------------
 tpl_2(raw_out).put(d);

 
endrule 
<%doc>
## COMMENTED ###############################################
`ifdef RAW_IO_TOFROM_NETWORK_SKETCH
 rule tonetwork;
   let d <- tpl_1(raw_in).get();
   //outFifo.enq(tuple4(address, tagged TTypeName sendobj_val, out_vc, opts));
   FlitHeaderPayLoad hf;
   hf.srcaddr = unpack(truncate(d.address)); 
   hf.ttag = pack(truncate(d.typetag));
   let utype = taggedTypeInTask_host(hf);
   tmp_loop_pipe.enq(d);
   $display("in tonetwork: ", fshow(d), " taggedType = ", fshow(utype));
 endrule
 
 rule fromnetwork;
 //let rdfrom = fromInteger(dict${_task_name}_srcaddr_to_zeroidx((tuple2(node_id, address))));
 //match {.address, .ttag, .opts} = inFifo[rdfrom].first; inFifo[rdfrom].deq;
 //inFifo.deq;
 let d = tmp_loop_pipe.first; tmp_loop_pipe.deq;
 tpl_2(raw_out).put(d);
  $display("in fromnetwork: ", fshow(d));
 endrule 
`endif 
## COMMENTED ###############################################
</%doc>
 
%if outgoing_types:
  interface getPacket = toGet(outFifo);
%endif 
endmodule //mk${_task_name}


##################################################################################################
##################################################################################################
## vim: ft=mako
