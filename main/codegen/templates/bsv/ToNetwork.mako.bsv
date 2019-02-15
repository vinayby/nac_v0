<%page args="_tm,_am"/>\
 <% 
 import pdb
 #_task_name = 'Task_'+ _tm.taskname
 _task_name = 'Task_'+ _tm.taskdefname
 incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
 outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]
 using_sync = True # TODO
  
 %>
 
##----1---------------------------------------------------------------------------------------------------------------- 
%if outgoing_types or using_sync:
##----1---------------------------------------------------------------------------------------------------------------- 
   
interface IToNetwork${_task_name};
  interface Vector#(NUM_VCS, Get#(Flit)) getFlit;
endinterface

##(* synthesize *)
%if _tm.is_task_instance():
module mkToNetwork${_task_name} (
  %if outgoing_types:
  FIFO#(DispatchUnion${_task_name}_tuple) inFifo, 
  %endif 
  MERGE_FIFOF#(${len(_am.tmodels)}, Flit) splfifo,
  DestAddr srcid, String snode_id, IToNetwork${_task_name} ifc); 

%else:
module mkToNetwork${_task_name} (
  %if outgoing_types:
  FIFO#(DispatchUnion${_task_name}_tuple) inFifo, 
  %endif 
  MERGE_FIFOF#(${len(_am.tmodels)}, Flit) splfifo,
  IToNetwork${_task_name} ifc); 

%endif

  %if outgoing_types:
  Vector#(NUM_VCS, FIFO#(Flit)) outFifo <- replicateM(mkSizedFIFO(${max(2, _tm.num_flits_in_dispatch_union())}));
  %else:
  Vector#(NUM_VCS, FIFO#(Flit)) outFifo <- replicateM(mkFIFO);
  %endif
  Vector#(${int(_am.get_max_parcel_size()/int(_am.psn.params['FLIT_DATA_WIDTH']))}, Reg#(FlitData)) vflits <- replicateM(mkReg(0));
  Reg#(Bit#(16)) flits2send <- mkReg(0);
  Reg#(Bit#(16)) f_idx <- mkReg(0);
  Reg#(DestAddr) dstaddr <- mkRegU;
  Reg#(VCType) outvc <- mkRegU;
  %if not _tm.is_task_instance():
  let dtlogger <- mkDebugTrace("log_ToNetwork${_task_name}", "${_tm.mapped_to_node}");
  %else:
  let dtlogger <- mkDebugTrace("log_ToNetwork${_task_name}", snode_id);
  %endif 

  rule priority_spl;
   let f = splfifo.first; splfifo.deq;
   %if _am.psn.is_fnoc():
   outFifo[0].enq(f);
   %else:
   outFifo[f.vc].enq(f);
   %endif 
  endrule 
   
  %if outgoing_types:
  (* descending_urgency = "priority_spl, r_first" *) // first flit, let priority_spl take it 
  rule r_first (flits2send == 0);
    //stage msg flits to send
    //source_address
    FlitHeaderPayLoad d_ = unpack(0);
    
    %if not _tm.is_task_instance():
    d_.srcaddr =  ${_tm.mapped_to_node};
    %else:
    d_.srcaddr = srcid;
    %endif
    
    let p = inFifo.first; inFifo.deq;
    match {.dst_addr, .taggedtype, .out_vc, .opts} = p;
    dstaddr <= dst_addr;
    outvc <= out_vc;
    %if outgoing_types:
    case (taggedtype) matches
      ##----------------------------------------------
      %for t in outgoing_types:
      tagged T${t} .obj: begin 
          flits2send <= ${_am.get_flits_in_type(t)};
          Bit#(${_am.get_max_parcel_size()}) cake = zeroExtend(pack(obj));
          Vector#(${int(_am.get_max_parcel_size()/int(_am.psn.params['FLIT_DATA_WIDTH']))}, FlitData) vf_ = toChunks(cake);
          writeVReg(vflits, vf_);
          d_.ttag = ${_am.typename2tag(t)};

          `ifdef INSTRUMENT_PRINTS
          dtlogger.trace($format("ev: send-out ; from: %d; to: %d ; type: ${t}", d_.srcaddr, dst_addr));
          `endif 
          `ifdef DEBUGPRINTS2
          dtlogger.debug($format(
                "${t} %d->%d (numflits=${_am.get_flits_in_type(t)}) \tpkt=", d_.srcaddr, dst_addr, fshow(p)
                ));
          `endif
      end 
      %endfor
      ##----------------------------------------------
      default: $display("**** NO MATCH **** ToNetwork ${_task_name}");
    endcase
  
    %endif
    
    FlitData d = pack(d_);
    // send the first flit with (tag, source_addr)
    let oflt = Flit{valid:1, is_tail:0, destAddr:dst_addr, vc:out_vc, data:d};
    outFifo[outvc].enq(oflt);
    `ifdef DEBUGPRINTS3
     dtlogger.debug($format(
          "${t} %d->%d Flit (ZERO of ${_am.get_flits_in_type(t)}) ", d_.srcaddr, dst_addr, fshow(oflt)
     ));

    `endif 
  endrule 

  (* descending_urgency = "r_rest, priority_spl" *) // while a packet io has already started, let spl flit wait
  rule r_rest ( !(flits2send == 0) );
    Bit#(1) is_tail = 0;
    if (flits2send == 1) begin
      is_tail = 1;
      f_idx <= 0;
    end else f_idx <= f_idx + 1;
    flits2send <= flits2send - 1;
    int idx = unpack(zeroExtend(pack(f_idx)));
    let xdata = readReg(vflits[idx]);
    let oflt = Flit{valid:1, is_tail:is_tail, destAddr:dstaddr, vc:outvc, data:xdata};
    outFifo[outvc].enq(oflt);
    `ifdef DEBUGPRINTS3
    %if not _tm.is_task_instance():
          dtlogger.debug($format(
          "${t} ${_tm.mapped_to_node}->%d Flit (%d of ${_am.get_flits_in_type(t)}) ",  dstaddr, idx, fshow(oflt)
          ));
    %else:
          dtlogger.debug($format(
          "${t} %d->%d Flit (%d of ${_am.get_flits_in_type(t)}) ",  srcid, dstaddr, idx, fshow(oflt)
          ));

    %endif
    `endif 
  endrule 
%endif ## outgoing types
  Vector#(NUM_VCS, Get#(Flit)) getFlitV = newVector;
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    getFlitV[i] = toGet(outFifo[i]);
  end
  interface getFlit = getFlitV;
endmodule 
##----1---------------------------------------------------------------------------------------------------------------- 
%endif ## if there are outgoing_types 
##----1---------------------------------------------------------------------------------------------------------------- 



##################################################################################################
##################################################################################################
## vim: ft=mako
