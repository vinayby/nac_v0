<%page args="_tm,_am"/>\
 <% 
 #_task_name = 'Task_'+ _tm.taskname
 _task_name = 'Task_'+ _tm.taskdefname
 incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
 outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]
 using_sync = True
 %>
 ##-----1--------------------------------------------------------------------------------------------------------------- 
%if incoming_types or using_sync:
 ##--------------------------------------------------------------------------------------------------------------------- 
  
interface IFromNetwork${_task_name}; 
  interface Vector#(NUM_VCS, Put#(Flit)) putFlit;
  %if incoming_types:
  interface Vector#(${len(_tm.get_unique_message_sources())}, Get#(ReceptionUnion${_task_name}_tuple)) getPacket; 
  %endif
endinterface 

##(* synthesize *)
%if _tm.is_task_instance():
module mkFromNetwork${_task_name} (\
  %if incoming_types:
  Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_task_name}_tuple)) outFifo, 
  %endif
  Vector#(${len(_am.tmodels)}, FIFO#(Flit)) splfifo, DestAddr dstid, String snode_id, IFromNetwork${_task_name} ifc); 

%else:
module mkFromNetwork${_task_name} (\
  %if incoming_types:
  Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_task_name}_tuple)) outFifo, 
  %endif
  Vector#(${len(_am.tmodels)}, FIFO#(Flit)) splfifo, IFromNetwork${_task_name} ifc); 
  
  DestAddr dstid = ${_tm.mapped_to_node};
  String snode_id = "${_tm.mapped_to_node}";

%endif

  function Action sendsplf(Flit f);
  return 
      (action
    %if _am.psn.is_fnoc_peek() and _am.args.fnoc_supports_multicast:
      FlitHeaderPayLoad fs = unpack(pack(f.data));
      let addr_ = fs.srcaddr;
    %else:
      FlitHeaderPayLoad fs = unpack(pack(f.data));
      let addr_ = fs.srcaddr;
    %endif
      splfifo[fromInteger(dict_srcaddr_to_zeroidx(addr_))].enq(f);
      endaction);
  endfunction 

%if incoming_types:
  Vector#(NUM_VCS, FIFOF#(Flit)) inFifo <- replicateM(mkFIFOF);
  Vector#(NUM_VCS, Reg#(ReceptionUnion${_task_name}_tuple)) staging <- replicateM(mkRegU);
  Vector#(NUM_VCS, Reg#(Bit#(18))) fc <- replicateM(mkReg(0)); // TODO check/warn (array sizes used in na)
                                 ## TODO fc width as per buffer-depth-etc
  let dtlogger <- mkDebugTrace("log_FromNetwork${_task_name}", snode_id);
  
  %for t in _tm.get_namelist_of_types():
  function ${t} updateObj${t}(${t} obj, FlitData d, int flit_index);
  Bit#(${_am.get_max_parcel_size()}) cake = zeroExtend(pack(obj));
  Vector#(${int(_am.get_max_parcel_size()/int(_am.psn.params['FLIT_DATA_WIDTH']))}, FlitData) vf = toChunks(cake);
    vf[flit_index]  = d;
    return unpack(truncate(pack(vf)));
  endfunction
  %endfor

  function Action debug_zerof(ReceptionUnion${_task_name}_tuple x, Flit f);
  return when((True),
    (action 
        match {.src_addr_dbg, .taggedtype_dbg, .opts_dbg} = x;
        %if incoming_types:
          case (taggedtype_dbg) matches
            %for t in incoming_types:
            tagged T${t} .obj: begin 
            `ifdef DEBUGPRINTS3
            dtlogger.debug($format(
            "${t} %d->%d Flit (ZERO of ${_am.get_flits_in_type(t)}) ", src_addr_dbg, dstid, fshow(f)
            ));
            `endif
            `ifdef INSTRUMENT_PRINTS
            dtlogger.trace($format("ev: recv-f0 ; from: %d; to: %d ; type: ${t}", src_addr_dbg, dstid));
            `endif
            end  
            %endfor
            default: $display("**** NO MATCH **** FromNetwork ${_task_name}");
          endcase
        %endif ## incoming types
      endaction));
  endfunction 


  function Action sendPkt(ReceptionUnion${_task_name}_tuple staging_next, SourceAddr src_addr);
  return when((True),
  (action
        outFifo[ fromInteger(dict${_task_name}_srcaddr_to_zeroidx(tuple2(dstid, src_addr))) ].enq(staging_next);
  endaction));
  endfunction 


  // VC 0 has higher priority
  Rules rr_pack = emptyRules();
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
  let rr = (rules 
    rule pack;
			Bit#(1) that_packs_this_type = 0;
      let f = inFifo[i].first; inFifo[i].deq;
      if (f.is_tail == 1)  fc[i] <= 0;
      else                 fc[i] <= fc[i] + 1;


      if( f.destAddr != dstid) 
      begin 
      $display("\tBADFLIT this is ${_task_name} @ %d but I received ", dstid, fshow(f));
      end 
      
      ReceptionUnion${_task_name}_tuple staging_next = staging[i];
      match {.src_addr, .taggedtype, .opts} = staging_next;

      if (fc[i] == 0) begin // first flit holds: (tag_id, src_addr), no msg
          if (f.is_tail == 1) begin // is a spl message: 1st flit, and is tail 
            sendsplf(f);
          end else begin // regular packet 
          let x = taggedTypeIn${_task_name}(unpack(f.data));
            staging[i] <= x;
            debug_zerof(x, f);
          end // spl packet 
      end // first flit
      else begin
    %if incoming_types:
        case (taggedtype) matches
          %for t in incoming_types:
          tagged T${t} .obj: begin 
            let obj1 = updateObj${t}(obj, f.data, unpack(zeroExtend(pack((fc[i]-1)% ${_am.get_flits_in_type(t)} )))); 
            staging_next = tuple3(src_addr, tagged T${t} obj1, opts);
					  if ( (fc[i])% ${_am.get_flits_in_type(t)}  == 0 ) that_packs_this_type = 1;
          `ifdef DEBUGPRINTS3
            dtlogger.debug($format(
            "${t} %d->%d Flit (%d of ${_am.get_flits_in_type(t)}) ", src_addr, dstid, fc[i], fshow(f)
            ));
          `endif
          end 
          %endfor
          default: $display("**** NO MATCH **** FromNetwork ${_task_name}");
        endcase
    %endif ## incoming types
        if (f.is_tail == 1 || that_packs_this_type == 1 ) 
          sendPkt(staging_next, src_addr);
        else 
          staging[i] <= staging_next;
        end 
    endrule 
  endrules);
  rr_pack = rJoinDescendingUrgency(rr_pack, rr);
  end // end for over NUM_VCS
  addRules(rr_pack);

%else: # only receives spl messages 
  Vector#(NUM_VCS, FIFOF#(Flit)) inFifo <- replicateM(mkFIFOF); 
  // VC 0 has higher priority
  Rules rr_spl_msgs = emptyRules();
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    let rr = (rules 
      rule spl_sole;
        let f = inFifo[i].first; inFifo[i].deq;
        if (f.is_tail == 1) begin 
          sendsplf(f);
        end 
        else
          $display("received stray tail flit in task ${_task_name}, dropping");
      endrule 
    endrules);
    rr_spl_msgs = rJoinDescendingUrgency(rr_spl_msgs, rr);
  end  //for
  addRules(rr_spl_msgs);
%endif // incoming_types
  Vector#(NUM_VCS, Put#(Flit)) putFlitV = newVector;
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    putFlitV[i] = toPut(inFifo[i]); 
  end

  interface putFlit = putFlitV;
endmodule 

##----1---------------------------------------------------------------------------------------------------------------- 
%endif ## if there are incoming types
##--------------------------------------------------------------------------------------------------------------------- 

##################################################################################################
##################################################################################################
## vim: ft=mako
