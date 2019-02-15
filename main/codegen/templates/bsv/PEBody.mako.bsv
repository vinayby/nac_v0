<%page args="_am,_tm,_task_name,type_table"/>\

<%
import pdb,math

%>
%if not _tm.is_task_instance():
  String task_instance_name = "${_tm.taskname}";
%endif

let dtlogger <- mkDebugTrace("log_"+task_instance_name, snode_id);
##################################################################################################
// encoding: if the first flit is tail flit, its an spl message
function Action send_synctoken(DestAddr dst, VCType out_vc, Bit#(4) opts);
return //when ((True),
(action
%if True:
  FlitHeaderPayLoad d_ = unpack(0);
  d_.srcaddr = node_id;
  FlitData d = pack(d_);
%else:
  FlitData d = 0;
  //d = zeroExtend(pack(node_id));
  d[${_am.getranges_tag_and_sourceaddr_info_in_flit()[1]}] = node_id;
  d[${_am.getranges_tag_and_sourceaddr_info_in_flit()[2]}] = opts;
%endif  
  let f = Flit{valid:1, is_tail:1, destAddr:dst, vc:out_vc, data:d};  
  if (node_id != dst) begin
  let tonode = fromInteger(dict_srcaddr_to_zeroidx(dst));  // 
  cmsgfifo_out.ports[tonode].enq(f);
  `ifdef SYNCDEBUG
  dtlogger.debug($format("\tsync\t%d->%d", node_id, dst));
  `endif
  end
  endaction);
endfunction  

%if _tm._gam.psn.is_fnoc():
// For ForthNoC supported multicasts; encoding: if the first flit is tail flit, its an spl message
function Action send_synctoken_auto_multicast(MultiCastMask mcm, bit is_multicast);
return //when ((True),
(action
FlitHeaderPayLoad d = unpack(0);
  d.srcaddr = node_id;
  VCType out_vc = 1; // set vc to 1 to mark it as broadcast/multicast
  if (is_multicast == 1)
  d.bcast_or_mcast = F_BROADCAST;
  else
  d.bcast_or_mcast = F_MULTICAST;
  MultiCastMask thisnode = unpack(1<<node_id);
  thisnode = invert(thisnode);
  d.mcm = mcm & thisnode; //switch off this node;
  let f = Flit{valid:1, is_tail:1, destAddr:0, vc:out_vc, data:pack(d)};  
  //if (node_id != dst) begin
  //let tonode = fromInteger(dict_srcaddr_to_zeroidx(dst));  // 
  cmsgfifo_out.ports[0].enq(f);
  `ifdef SYNCDEBUG
  dtlogger.debug($format("\tsync\t%d-> ", node_id, fshow(d), fshow(f)));
  `endif
  //end
  endaction);
endfunction  
%endif

function ActionValue#(SourceAddr) recv_synctoken(SourceAddr addr);
return //when ((True),
  (actionvalue
  if (addr != node_id) begin 
  let rdfrom = fromInteger(dict_srcaddr_to_zeroidx(addr));
  let f = cmsgfifo_in[rdfrom].first; cmsgfifo_in[rdfrom].deq;
  //SourceAddr src = truncate(pack(f.data));
  %if _am.psn.is_fnoc_peek() and _am.args.fnoc_supports_multicast:
    FlitHeaderPayLoad fs = unpack(pack(f.data));
    let src = fs.srcaddr;
  %else:
    FlitHeaderPayLoad d_ = unpack(pack(f.data));
    let src = d_.srcaddr;
  %endif
  `ifdef SYNCDEBUG
  dtlogger.debug($format("\tgotsync\t%d<-%d ", node_id, src, fshow(f)));
  `endif
  return src;
  end else  
    return addr;
  endactionvalue);
endfunction  

function Action synchronous_recv_ack(SourceAddr srcaddr);
return // when ((True),
(action 
  let a <- recv_synctoken(srcaddr);
  send_synctoken(a, 0, 0);
  dtlogger.debug($format("\trecv::sync\tOK (exp: %d, got: %d)\tsending ACK to %d", srcaddr, a, a));
endaction);
endfunction 


%if _tm.iff_use_mergefifo:
function ActionValue#(SourceAddr) recv_synctoken_any();
return // when ((True),
  (actionvalue
  let f = mergeF_cmsg_in.first; mergeF_cmsg_in.deq;
    FlitHeaderPayLoad d_ = unpack(pack(f.data));
    let src = d_.srcaddr;

  `ifdef SYNCDEBUG
  dtlogger.debug($format("\tgotsync\t%d<-%d (SYNCANY) ", node_id, src));
  `endif
  return src;
  endactionvalue);
endfunction  

function Action synchronous_recv_ack_any();
return // when ((True),
(action 
  let a <- recv_synctoken_any();
  send_synctoken(a, 0, 0);
  dtlogger.debug($format("\trecv_sync (exp: ANY, got=%d) ", a));
endaction);
endfunction 
%endif
##################################################################################################
Reg#(NATaskInfo) task_info <- mkReg(unpack(extend(pack(node_id))));  
// Storage definitions
%for k, v in _tm.symbol_table.items():
  <%
    dict_var_npoa, sendrecv_class_nodes = _tm.get_dict_instance_symbol_to_number_of_points_of_access()
  %>
  %if v.storage_class == '__fifo__':  
    Reg#(Bit#(${v.arraysizewidth})) ${k}_index <- mkReg(0); // TODO protections for parallel access
    %if v.arraysize == 1:
      FIFOF#(${v.typename}) ${k} <- mkFIFOF;
    %else:
      FIFOF#(${v.typename}) ${k} <- mkSizedFIFOF(${v.arraysize});
    %endif
  %elif v.storage_class == '__bram__':
    %if v.arraysize > 1:
      Reg#(Bit#(${v.arraysizewidth})) ${k}_index <- mkReg(0);
      %for srn in sendrecv_class_nodes:
        Reg#(Bit#(${v.arraysizewidth})) ${k}_index_${srn.lineinfo[0]} <- mkReg(0);
      %endfor
      Reg#(${v.typename}) ${k}_reg <- mkRegU; 
      %if v.has_fromfile_initializer:
        BRAM_Configure cfg${k} = BRAM_Configure{memorySize:${v.arraysize}, latency: 1, outFIFODepth: 2, loadFormat: tagged Hex ${v.fromfile_initializer}, allowWriteResponseBypass: False};
    %else:
      BRAM_Configure cfg${k} = BRAM_Configure{memorySize:${v.arraysize}, latency: 1, outFIFODepth: 2, loadFormat: None, allowWriteResponseBypass: False};
    %endif
      BRAM2Port#(Bit#(${v.arraysizewidth}), ${v.typename}) ${k} <- mkBRAM2Server(cfg${k});
    %endif 
  %elif v.storage_class == '__ram__':
    %if v.arraysize > 1:
      Reg#(Bit#(${v.arraysizewidth})) ${k}_index <- mkReg(0);
      %for srn in sendrecv_class_nodes:
        Reg#(Bit#(${v.arraysizewidth})) ${k}_index_${srn.lineinfo[0]} <- mkReg(0);
      %endfor
      MEMORY_IFC# (Bit#(${v.arraysizewidth}), ${v.typename}) ${k} <- mkBRAMSized(${v.arraysize});
    %endif 
  %elif v.storage_class == '__mbus__':
    %if v.arraysize > 1:
      Reg#(Bit#(${v.arraysizewidth})) ${k}_index <- mkReg(0);
      %for srn in sendrecv_class_nodes:
        Reg#(Bit#(${v.arraysizewidth})) ${k}_index_${srn.lineinfo[0]} <- mkReg(0);
      %endfor
      //BRAM_Configure cfg${k} = BRAM_Configure{memorySize:${v.arraysize}, latency: 1, outFIFODepth: 2, loadFormat: None, allowWriteResponseBypass: False};
      //BRAM2Port#(Bit#(${v.arraysizewidth}), ${v.typename}) ${k} <- mkBRAM2Server(cfg${k});
      MEMORY_IFC#(Bit#(${v.arraysizewidth}),  ${v.typename}) ${k} <- mkBRAMSized(${v.arraysize});
    %endif 
  %elif v.storage_class == '__reg__':
    %if v.arraysize == 1:
      Reg#(${v.typename}) ${k} <- mkReg(defaultValue);
    %else:
      Reg#(Bit#(${v.arraysizewidth})) ${k}_index <- mkReg(0);
      %for srn in sendrecv_class_nodes:
        Reg#(Bit#(${v.arraysizewidth})) ${k}_index_${srn.lineinfo[0]} <- mkReg(0);
      %endfor
      %if v.has_fromfile_initializer:
      RegFile#(Bit#(${v.arraysizewidth}), ${v.typename}) ${k} <- mkRegFileLoad(${v.fromfile_initializer}, 0, (${v.arraysize-1}));
      %else:
      RegFile#(Bit#(${v.arraysizewidth}), ${v.typename}) ${k} <- mkRegFile(0, (${v.arraysize-1}));
      %endif 
    %endif 
  %else:
    NOTSUPPORTED_YET 
  %endif 
%endfor
########### Loop indices
<%
  loopvar_names = _tm.get_loopvar_names_of_loop_statements()
%>
%for lv in loopvar_names:
  Reg#(Bit#(16))  loopidx_${lv} <- mkReg(0);
%endfor 
########### Loop indices for repeat(nonzero) statements
%for e in _tm.get_loop_repeat_statements():
  Reg#(Bit#(16))  repeatcount_${e.stmtuniq_tag} <- mkReg(0);
%endfor 

########### Special flags
## PingPong send and recv staements 
%for b in _tm.get_send_recv_statements_tagged_pingpong():
  Reg#(bit) pingpong_${b.lineno} <- mkReg(1);
%endfor 


##################################################################################################
<%def name="EV_TS_TOP(b=None,forcedebug=False)">
  %if _am.args.event_trace:
    dtlogger.trace($format("ev_ts: top; lvl: ${b.depth}; lno: ${b.lineno}; name: ${b.name}"));
  %endif
</%def>\
<%def name="EV_TS_BOTTOM(b=None,forcedebug=False)">
  %if _am.args.event_trace:
    dtlogger.trace($format("ev_ts: bottom; lvl: ${b.depth}; lno: ${b.lineno}; name: ${b.name}"));
  %endif
</%def>\

##################################################################################################
<%def name="ENTRY_LOG(b=None,forcedebug=False)">
  %if forcedebug or _am.trace_state_entry_exit():
    %if b.name in ['kernel_call']:
      dtlogger.debug($format("STATE (enter)\t${b.stmtuniq_tag} (${b.kernel_name})"));
    %else:
      dtlogger.debug($format("STATE (enter)\t${b.stmtuniq_tag} "));
    %endif
%else:
  %if b.name in ['send', 'scatter', 'barrier', 'recv', 'gather']:
    noAction; //TODOJ fix
  %endif 
%endif  
</%def>\
<%def name="EXIT_LOG(b=None, forcedebug=False)">
%if forcedebug or _am.trace_state_entry_exit():
    %if b.name in ['kernel_call' ]:
      dtlogger.debug($format("STATE (exit)\t${b.stmtuniq_tag} (${b.kernel_name})"));
    %else:
      dtlogger.debug($format("STATE (exit)\t${b.stmtuniq_tag} "));
    %endif
%else:
  %if b.name in ['send', 'scatter', 'barrier', 'recv', 'gather']:
    noAction; //TODOJ fix shifted to the exit side
  %endif 
%endif  
</%def>\
##################################################################################################
// Instantiating hwkernel modules (singleton kernel instances)
%for modname, knode in _tm.get_hwkernel_modnames():
  let ${knode.stmtuniq_tag}${modname} <- mk${modname}(dtlogger, ${_tm.get_csv_arguments_for_kernel(modname, knode=knode)});
%endfor 
##################################################################################################
##################################################################################################
<%def name="body_mcopy(b)">
  <% 
   sefrom = _tm.symbol_table[b.varfrom]
   seto = _tm.symbol_table[b.varto]
   offset, length = b.offset,b.length
   if length == 'all':
     length = sefrom.arraysize-offset
   infer_loop = length > 1
  %>\
  
  %if infer_loop:
    repeat(${length}) seq
  %endif 
   %if sefrom.storage_class == '__bram__':
    ${b.varfrom}.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ${b.varfrom}_index+${offset}});
  %elif sefrom.storage_class == '__ram__':
    ${b.varfrom}.readReq(${b.varfrom}_index + ${offset});
  %elif sefrom.storage_class == '__mbus__':
    ${b.varfrom}.readReq(${b.varfrom}_index + ${offset});
  %endif
  action
    %if sefrom.storage_class == '__fifo__':
      let obj_val = ${b.varfrom}.first;
      ${b.varfrom}.deq;
    %elif sefrom.storage_class == '__bram__':
        let obj_val <- ${b.varfrom}.portA.response.get;
        if (${b.varfrom}_index < ${length-1})
          ${b.varfrom}_index <= ${b.varfrom}_index + 1;
        else 
          ${b.varfrom}_index <= 0;
    %elif sefrom.storage_class == '__ram__':
        let obj_val <- ${b.varfrom}.readRsp();
        if (${b.varfrom}_index < ${length-1})
          ${b.varfrom}_index <= ${b.varfrom}_index + 1;
        else 
          ${b.varfrom}_index <= 0;
    %elif sefrom.storage_class == '__mbus__':
        //let obj_val <- ${b.varfrom}.mem.portA.response.get;
        let obj_val <- ${b.varfrom}.readRsp();
        if (${b.varfrom}_index < ${length-1})
          ${b.varfrom}_index <= ${b.varfrom}_index + 1;
        else 
          ${b.varfrom}_index <= 0;
    %elif sefrom.storage_class == '__reg__':
      %if length == 1:
        let obj_val = ${b.varfrom};
      %else:
        let obj_val = ${b.varfrom}.sub(${b.varfrom}_index+${offset});
        if (${b.varfrom}_index < ${length-1})
          ${b.varfrom}_index <= ${b.varfrom}_index + 1;
        else 
          ${b.varfrom}_index <= 0;
      %endif 
    %endif ## sefrom.storage_class
    //$display("[%d] ${b.stmtuniq_tag} instance=${b.varfrom}\t", cticks, fshow(obj_val),task_instance_name);

   %if seto.storage_class == '__bram__':
     ${b.varto}.portA.request.put(BRAMRequest{write: True, responseOnWrite: False, address: ${b.varfrom}_index+${offset}, datain:obj_val});
   %elif seto.storage_class == '__fifo__':
     ${b.varto}.enq(obj_val);
   %elif seto.storage_class == '__reg__':
     %if length == 1:
       ${b.varto} <= (obj_val);
     %else:
       TODO
     %endif 
  %elif seto.storage_class == '__ram__':
    TODO//${b.varto}.readReq(${b.varto}_index + ${offset});
  %elif seto.storage_class == '__mbus__':
    TODO//${b.varto}.readReq(${b.varto}_index + ${offset});
  %endif

  endaction 
  %if infer_loop:
    endseq
  %endif 

</%def>
##################################################################################################

##################################################################################################
<%def name="body_display(b)">
  <% 
   se = _tm.symbol_table[b.var]
   infer_loop = se.arraysize > 1
   offset, length = b.offset,b.length
   if length == 'all':
     length = se.arraysize-offset
  %>\
  
  %if infer_loop:
    repeat(${length}) seq
  %endif 
   %if se.storage_class == '__bram__':
    ${b.var}.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ${b.var}_index+${offset}});
  %elif se.storage_class == '__ram__':
    ${b.var}.readReq(${b.var}_index + ${offset});
  %elif se.storage_class == '__mbus__':
    ${b.var}.readReq(${b.var}_index + ${offset});
  %endif
  action
    %if se.storage_class == '__fifo__':
      let obj_val = ${b.var}.first;
      ${b.var}.deq;
    %elif se.storage_class == '__bram__':
        let obj_val <- ${b.var}.portA.response.get;
        if (${b.var}_index < ${length-1})
          ${b.var}_index <= ${b.var}_index + 1;
        else 
          ${b.var}_index <= 0;
    %elif se.storage_class == '__ram__':
        let obj_val <- ${b.var}.readRsp();
        if (${b.var}_index < ${length-1})
          ${b.var}_index <= ${b.var}_index + 1;
        else 
          ${b.var}_index <= 0;
    %elif se.storage_class == '__mbus__':
        //let obj_val <- ${b.var}.mem.portA.response.get;
        let obj_val <- ${b.var}.readRsp();
        if (${b.var}_index < ${length-1})
          ${b.var}_index <= ${b.var}_index + 1;
        else 
          ${b.var}_index <= 0;
    %elif se.storage_class == '__reg__':
      %if length == 1:
        let obj_val = ${b.var};
      %else:
        let obj_val = ${b.var}.sub(${b.var}_index+${offset});
        if (${b.var}_index < ${length-1})
          ${b.var}_index <= ${b.var}_index + 1;
        else 
          ${b.var}_index <= 0;
      %endif 
    %endif ## se.storage_class
    dtlogger.debug($format(" ${b.stmtuniq_tag} instance=${b.var}\t", fshow(obj_val)));
  endaction 
  %if infer_loop:
    endseq
  %endif 

</%def>
##################################################################################################
<%def name="body_delay(b)">
  delay(${b.delayccs});
</%def>
##################################################################################################
<%def name="body_halt(b)">
  ${ENTRY_LOG(b=b)}
  dtlogger.debug($format(" ${b.stmtuniq_tag}\t"));
  %if b.signum:
    $finish(0);
  %else:
    await(False);
  %endif
  ${EXIT_LOG(b=b)}
</%def>
##################################################################################################
<%def name="body_recv(b)">
  <%
   se = _tm.symbol_table[b.var] 
   infer_loop = se.arraysize > 1
   offset, length = b.offset,b.length
   if length == 'all':
     length = se.arraysize-offset
   multiple_sources = len(b.address_list)>1
   # same as in send
   sync_send = False
   roundrobin_destination = False
   blocking = False
   use_half_pingpong = False
   opts_ = 0
   if 'sync' in b.opts:
     sync_send = True
     opts_ = opts_ | 1<<1;
   if 'roundrobin' in b.opts:
     roundrobin_destination = True
   if 'b' in b.opts:
     blocking = True
     opts_ = opts_ | 1<<0;
   if 'pingpong' in b.opts:
     use_half_pingpong = True
     #length = length // 2
   #pdb.set_trace()
  %>\

  //XX recv from ${offset}, ${length} items, ${b.opts}
  %if sync_send:
  %if _tm.iff_use_mergefifo:
  synchronous_recv_ack_any();
  %else:
  synchronous_recv_ack(${_am.taskmap(b.address_list[0])});
  %endif
  %endif
  %if infer_loop:
  repeat(${length}) seq 
  %endif 
  ${ENTRY_LOG(b=b)}
  action
  %if _tm.iff_use_mergefifo:
      match {.address, .ttag, .opts} = mergeF.first; mergeF.deq;
      saved_source_address <= address;
  %else:
      let rdfrom = fromInteger(dict${_task_name}_srcaddr_to_zeroidx((tuple2(node_id, ${_am.taskmap(b.address_list[0])}))));
      match {.address, .ttag, .opts} = inFifo[rdfrom].first; inFifo[rdfrom].deq;
      saved_source_address <= address;// to respond to blocking send
  %endif
  let inobj = ttag.T${se.typename};
  let typematch = ttag matches tagged T${se.typename} .v ? True : False;
  %if not _tm.iff_use_mergefifo:
  let sourcematch = address == ${_am.taskmap(b.address_list[0])};
  if (!typematch || !sourcematch) 
    $display("address(mismatch? %d (exp:%d, got:%d))/type(mismatch? %d)%s ${b.stmtuniq_tag}", !sourcematch,${_am.taskmap(b.address_list[0])},address,!typematch, task_instance_name );
  %endif    
  %if se.storage_class == '__fifo__':
    ${b.var}.enq(inobj);
  %elif se.storage_class == '__bram__':
      //${b.var}.upd(${b.var}_index_${b.lineno}, inobj);
    %if use_half_pingpong:
        if(pingpong_${b.lineno}==1) 
      ${b.var}.portA.request.put(BRAMRequest{write:True, responseOnWrite: False, address: ${b.var}_index_${b.lineno} + ${offset}, datain: inobj});
        else 
      ${b.var}.portA.request.put(BRAMRequest{write:True, responseOnWrite: False, address: ${b.var}_index_${b.lineno} + ${length} - ${offset}, datain: inobj});
    %else:
      ${b.var}.portA.request.put(BRAMRequest{write:True, responseOnWrite: False, address: ${b.var}_index_${b.lineno} + ${offset}, datain: inobj});
    %endif
      if (${b.var}_index_${b.lineno} < ${length-1})
        ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
      else 
         ${b.var}_index_${b.lineno} <= 0;
  %elif se.storage_class == '__ram__':
      ${b.var}.write(${b.var}_index_${b.lineno} + ${offset}, inobj);
      if (${b.var}_index_${b.lineno} < ${length-1})
        ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
      else 
        ${b.var}_index_${b.lineno} <= 0;
  %elif se.storage_class == '__mbus__':
      //${b.var}.upd(${b.var}_index_${b.lineno}, inobj);
      //${b.var}.portA.request.put(BRAMRequest{write:True, responseOnWrite: False, address: ${b.var}_index_${b.lineno}, datain: inobj});
      await(${b.var}.notFull); //TODO conservative, write requests accepted
      ${b.var}.write(${b.var}_index_${b.lineno}+${offset}, inobj);
      if (${b.var}_index_${b.lineno} < ${length-1})
        ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
      else 
        ${b.var}_index_${b.lineno} <= 0;
  %elif se.storage_class == '__reg__':
    %if length == 1:
      %if infer_loop:
          ${b.var}.upd(${offset}, inobj);
      %else:
        ${b.var}._write(inobj);
      %endif 
    %else:
      ${b.var}.upd(${b.var}_index_${b.lineno}+${offset}, inobj);
      if (${b.var}_index_${b.lineno} < ${length-1})
        ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
      else 
        ${b.var}_index_${b.lineno} <= 0;
    %endif 
  %endif ## se.storage_class
  endaction 
  %if infer_loop:
    endseq 
  %endif 
  ${EXIT_LOG(b=b)}
  %if blocking:
  action 
  //if(0 != (opts & 1<<0)) // blocking send, dont have to use recv:b... register opts so can be used here when done recving
  send_synctoken(saved_source_address, 0, 0);
  endaction
  %endif
  %if use_half_pingpong:
  pingpong_${b.lineno} <= ~pingpong_${b.lineno};
%endif
</%def>


##################################################################################################
<%def name="body_gather(b)">
  ${ENTRY_LOG(b=b)}
  <%
    se = _tm.symbol_table[b.var]
    offset, length = b.offset,b.length
    if length == 'all':
      length = se.arraysize-offset
    address_list = list(map(_am.taskmap, b.address_list))
    items_per_address = length//len(address_list)
    out_vc = 0
  %>\
  %for chunk_index, address in enumerate(address_list):
     repeat(${items_per_address})
     seq

  

     action

      let rdfrom = fromInteger(dict${_task_name}_srcaddr_to_zeroidx((tuple2(node_id, ${_am.taskmap(address)}))));
  match {.address, .ttag, .opt} = inFifo[rdfrom].first; inFifo[rdfrom].deq;
  let inobj = ttag.T${se.typename};
  let typematch = ttag matches tagged T${se.typename} .v ? True : False;
  let sourcematch = address == ${_am.taskmap(address)};
  if (!typematch || !sourcematch) 
  $display("address(mismatch? %d (exp:%d, got:%d))/type(mismatch? %d)%s ${b.stmtuniq_tag}", !sourcematch,${_am.taskmap(address)},address,!typematch, task_instance_name );

       %if se.storage_class == '__fifo__':
           ${b.var}.enq(inobj);
       %elif se.storage_class == '__bram__':
         %if length == 1:
           // scattering 1 item not supported
         %else:
             ${b.var}.portA.request.put(BRAMRequest{write:True, responseOnWrite: False, address: 
             (${chunk_index*items_per_address}+${b.var}_index_${b.lineno}+${offset}) , datain: inobj});
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
         %endif 
       %elif se.storage_class == '__ram__':
           ${b.var}.write((${chunk_index*items_per_address}+${b.var}_index_${b.lineno}+${offset}) , inobj);
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
       %elif se.storage_class == '__mbus__':
         %if length == 1:
           // scattering 1 item not supported
         %else:
             //let sendobj_val <- ${b.var}.readRsp(); //suv
          await(${b.var}.notFull); //TODO conservative, write requests accepted
          ${b.var}.write((${chunk_index*items_per_address}+${b.var}_index_${b.lineno}+${offset}), inobj);
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
         %endif 
       %elif se.storage_class == '__reg__':
         %if length == 1:
           // scattering 1 item not supported
         %else:
             ${b.var}.upd(${chunk_index*items_per_address}+${b.var}_index_${b.lineno}+${offset}, inobj);
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
         %endif 
       %endif ## se.storage_class
     endaction 
     endseq 
  %endfor
  ${EXIT_LOG(b=b)}
</%def>
##################################################################################################
##################################################################################################
<%def name="body_barrier(b)">
<% 
 out_vc = 0
 address = _am.taskmap(b.address_list[0])
 address_list = list(map(_am.taskmap, b.address_list))
 grouplen = int(math.ceil(math.log(len(address_list), 2)))   
 mcm = 0
 for a in address_list:
   mcm |= 1<<a;
 %>\
 ${ENTRY_LOG(b, True)}
%if _am.args.fnoc_supports_multicast:
    send_synctoken_auto_multicast(fromInteger(${mcm}), 1);
    par 
  %for address in address_list:
      seq     action let dontcarer <- recv_synctoken(${address}); endaction    endseq
    %endfor
    endpar 
%else:
 %for address in address_list:
     %if _am.psn.is_fnoc_peek():
     send_synctoken(${address}, 0, 0);
     %else:
     send_synctoken(${address}, 1, 0);
     %endif
  %endfor
  par 
  %for address in address_list:
      seq     action let dontcarer <- recv_synctoken(${address}); endaction    endseq
  %endfor 
  endpar 
%endif   
  ${EXIT_LOG(b, True)}
</%def>
##################################################################################################
##################################################################################################
## send
<%def name="fetch_read_response_to_a_reg(se, b, offset)">
  %if se.storage_class == '__bram__':
    ${b.var}.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ${b.var}_index_${b.lineno}+${offset}});
    action 
    let rx <- ${b.var}.portA.response.get; 
    ${b.var}_reg <= rx;
    endaction 
\
  %elif se.storage_class == '__ram__':
    ${b.var}.readReq(${b.var}_index_${b.lineno} + ${offset});
    action 
    let rx <- ${b.var}.readResp(); 
    ${b.var}_reg <= rx;
    endaction 
\ 
  %elif se.storage_class == '__mbus__':
    ${b.var}.readReq(${b.var}_index_${b.lineno} + ${offset});
    let rx <- ${b.var}.readResp(); 
    ${b.var}_reg <= rx;
    endaction 
\ 
  %endif
</%def>
<%def name="collect_and_send_out_action(se, b, address, out_vc, last_destination_address, length)">
  action
  SendXOpt opts = P_NONE;
    %if se.storage_class == '__fifo__':
      let sendobj_val = ${b.var}.first;
      XX review
      %if last_destination_address:
      ${b.var}.deq;
      %endif 
    %elif se.storage_class == '__bram__':
        let sendobj_val = ${b.var}_reg;
        %if last_destination_address:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else  begin 
          ${b.var}_index_${b.lineno} <= 0;
          //opts = 1;
        end 
        %endif
    %elif se.storage_class == '__ram__':
        let sendobj_val = ${b.var}_reg;
        %if last_destination_address:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else begin
          ${b.var}_index_${b.lineno} <= 0;
//           opts = 1;
        end 
        %endif
    %elif se.storage_class == '__mbus__':
        //let sendobj_val <- ${b.var}.mem.portA.response.get;
        //let sendobj_val <- ${b.var}.readRsp();
        let sendobj_val = ${b.var}_reg;
        %if last_destination_address:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else begin
          ${b.var}_index_${b.lineno} <= 0;
//           opts = 1;
        end 
        %endif
    %elif se.storage_class == '__reg__':
      %if length == 1:
        let sendobj_val = ${b.var};
//         opts = 1;
      %else:
        let sendobj_val = ${b.var}.sub(${b.var}_index_${b.lineno});
        %if last_destination_address:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else begin 
          ${b.var}_index_${b.lineno} <= 0;
//           opts = 1;
        end 
       %endif
      %endif 
    %endif ## se.storage_class
    %if _am.args.new_tofrom_network:
//         opts = 0;
    %endif 
    outFifo.enq(tuple4(${address}, tagged T${se.typename} sendobj_val, ${out_vc}, opts));
  endaction 
</%def>
<%def name="body_broadcast(b)">
  <% 
   se = _tm.symbol_table[b.var]
   infer_loop = se.arraysize > 1
   offset, length = b.offset,b.length
   if length == 'all':
     length = se.arraysize-offset
   out_vc = 0
   address_list = list(map(_am.taskmap, b.address_list))
   send_depth_first = True
  %>\
%if send_depth_first:
  %for address_idx, address in enumerate(address_list):
  ${ENTRY_LOG(b=b)}
    %if infer_loop:
    repeat(${length}) seq
    %endif
    ${fetch_read_response_to_a_reg(se, b, offset)}
    ${collect_and_send_out_action(se, b, address, out_vc, True, length)}
    %if infer_loop:
    endseq
    %endif 
  ${EXIT_LOG(b=b)}
  %endfor 
%else:
  %if infer_loop:
  repeat(${length}) seq 
  %endif 
  ${ENTRY_LOG(b=b)}
  ${fetch_read_response_to_a_reg(se, b, offset)}
  %for address_idx, address in enumerate(address_list):
      ${collect_and_send_out_action(se, b, address, out_vc, address_idx == len(address_list)-1, length)}
  %endfor 
  ${EXIT_LOG(b=b)}
  %if infer_loop:
    endseq
  %endif 
%endif
\
</%def>
##################################################################################################
## send each element to every address, and repeat with the next element
<%def name="body_broadcast_longform(b)">
  <% 
   se = _tm.symbol_table[b.var]
   infer_loop = se.arraysize > 1
   offset, length = b.offset,b.length
   if length == 'all':
     length = se.arraysize-offset
   out_vc = 0
   address_list = list(map(_am.taskmap, b.address_list))
  %>\
  %if infer_loop:
    repeat(${length}) seq
  %endif 
  ${ENTRY_LOG(b=b)}
  %if se.storage_class == '__bram__':
    ${b.var}.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ${b.var}_index_${b.lineno}+${offset}});
    action 
    let rx <- ${b.var}.portA.response.get; 
    ${b.var}_reg <= rx;
    endaction 
\
  %elif se.storage_class == '__ram__':
    ${b.var}.readReq(${b.var}_index_${b.lineno});
    action 
    let rx <- ${b.var}.readResp(); 
    ${b.var}_reg <= rx;
    endaction 
\ 
  %elif se.storage_class == '__mbus__':
    ${b.var}.readReq(${b.var}_index_${b.lineno});
    let rx <- ${b.var}.readResp(); 
    ${b.var}_reg <= rx;
    endaction 
\ 
  %endif
  %for address_idx, address in enumerate(address_list):
  action
    %if se.storage_class == '__fifo__':
      let sendobj_val = ${b.var}.first;
      %if address_idx == len(address_list)-1:
      ${b.var}.deq;
      %endif 
    %elif se.storage_class == '__bram__':
        let sendobj_val = ${b.var}_reg;
        %if address_idx == len(address_list)-1:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else 
          ${b.var}_index_${b.lineno} <= 0;
        %endif
    %elif se.storage_class == '__ram__':
        let sendobj_val = ${b.var}_reg;
        %if address_idx == len(address_list)-1:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else 
          ${b.var}_index_${b.lineno} <= 0;
        %endif
    %elif se.storage_class == '__mbus__':
        //let sendobj_val <- ${b.var}.mem.portA.response.get;
        //let sendobj_val <- ${b.var}.readRsp();
        let sendobj_val = ${b.var}_reg;
        %if address_idx == len(address_list)-1:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else 
          ${b.var}_index_${b.lineno} <= 0;
        %endif
    %elif se.storage_class == '__reg__':
      %if length == 1:
        let sendobj_val = ${b.var};
      %else:
        let sendobj_val = ${b.var}.sub(${b.var}_index_${b.lineno});
        %if address_idx == len(address_list)-1:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else 
          ${b.var}_index_${b.lineno} <= 0;
       %endif
      %endif 
    %endif ## se.storage_class
    outFifo.enq(tuple4(${address}, tagged T${se.typename} sendobj_val, ${out_vc}, 0));
  endaction 
  %endfor 
  ${EXIT_LOG(b=b)}
  %if infer_loop:
    endseq
  %endif 
</%def>
##################################################################################################
##################################################################################################
<%def name="body_send(b)">
  <% 
   se = _tm.symbol_table[b.var]
   infer_loop = se.arraysize > 1
   offset, length = b.offset,b.length
   if length == 'all':
     length = se.arraysize-offset
   out_vc = 0
   address_list = b.address_list
   address = _am.taskmap(address_list[0])
   address_list = list(map(_am.taskmap, address_list))
   sync_send = False
   roundrobin_destination = False
   blocking = False
   use_half_pingpong = False
   opts_ = 0
   if 'sync' in b.opts:
     sync_send = True
     opts_ = opts_ | 1<<1;
   if 'roundrobin' in b.opts:
     roundrobin_destination = True
   if 'b' in b.opts:
     blocking = True
     opts_ = opts_ | 1<<0;
   if 'pingpong' in b.opts:
     use_half_pingpong = True
     #length = length // 2
   #pdb.set_trace()
  %>\
  %if roundrobin_destination:
    //ROUNDROBIN
  %endif
  %for address_idx, address in enumerate(address_list):
  %if sync_send:
      noAction; //TODOJ can mix-in with the body of another HEADTAIL packet as this flit has a higher priority
      send_synctoken(${address}, 0, 0);
    action 
      let dontcarer <-  recv_synctoken(${address}); 
      dtlogger.debug($format("\tsend:sync OK (to=%d, respfrom=%d)", ${address}, dontcarer));
    endaction 
    ## TODOJ wrap it up in function returning Stmt
  %endif
  %if infer_loop:
    repeat(${length}) seq
  %endif 
  ${ENTRY_LOG(b=b)}
  %if se.storage_class == '__bram__':
      %if use_half_pingpong:
        if(pingpong_${b.lineno}==1) 
        ${b.var}.portA.request.put(BRAMRequest{write:False, responseOnWrite: False, address: ${b.var}_index_${b.lineno} + ${offset}});
        else 
        ${b.var}.portA.request.put(BRAMRequest{write:False, responseOnWrite: False, address: ${b.var}_index_${b.lineno} + ${length} - ${offset}});
      %else:
    ${b.var}.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: ${b.var}_index_${b.lineno}+${offset}});
      %endif
  %elif se.storage_class == '__ram__':
    ${b.var}.readReq(${b.var}_index_${b.lineno}+${offset});
  %elif se.storage_class == '__mbus__':
    ${b.var}.readReq(${b.var}_index_${b.lineno}+${offset});
  %endif
    action
    SendXOpt opts = P_NONE;
    
    %if se.storage_class == '__fifo__':
      let sendobj_val = ${b.var}.first;
      
      %if address_idx == len(address_list)-1:
      ${b.var}.deq;
      %endif 
      
      %if _am.args.new_tofrom_network:
//           TODO opts send for FIFOs
        if (0==${b.var}_index) opts = P_HEAD; 
        if (${b.var}_index < ${length-1})
          ${b.var}_index <= ${b.var}_index + 1;
        else begin 
        ${b.var}_index <= 0; 
        opts = P_TAIL; 
        end 
      %else:
         opts = P_HEADTAIL; // if old tofrom-nw mode
      %endif
    
    
    %elif se.storage_class == '__bram__':
      let sendobj_val <- ${b.var}.portA.response.get;
      ##%if address_idx == len(address_list)-1: ## TODOJ
      if (0==${b.var}_index_${b.lineno}) opts = P_HEAD; 
      if (${b.var}_index_${b.lineno} < ${length-1})
        ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
      else begin 
      ${b.var}_index_${b.lineno} <= 0; 
      opts = P_TAIL; 
      end 
      ##%endif
    %elif se.storage_class == '__ram__':
      let sendobj_val <- ${b.var}.readRsp();
        if (0==${b.var}_index_${b.lineno}) opts = P_HEAD; 
      %if address_idx == len(address_list)-1:
      if (${b.var}_index_${b.lineno} < ${length-1})
        ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
      else begin
        ${b.var}_index_${b.lineno} <= 0;
        opts = P_TAIL; 
      end 
      %endif
    %elif se.storage_class == '__mbus__':
      //let sendobj_val <- ${b.var}.mem.portA.response.get;
      let sendobj_val <- ${b.var}.readRsp();
        if (0==${b.var}_index_${b.lineno}) opts = P_HEAD; 
      %if address_idx == len(address_list)-1:
      if (${b.var}_index_${b.lineno} < ${length-1})
        ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
      else begin 
        ${b.var}_index_${b.lineno} <= 0;
        opts = P_TAIL; 
      end 
      %endif
    %elif se.storage_class == '__reg__':
      %if length == 1:
       opts = P_HEADTAIL; 
	     %if infer_loop:
         let sendobj_val =  ${b.var}.sub(${offset});
     	 %else:
          let sendobj_val = ${b.var};
      	 %endif 
      %else:
        let sendobj_val = ${b.var}.sub(${b.var}_index_${b.lineno});
        %if address_idx == len(address_list)-1:
        if (0==${b.var}_index_${b.lineno}) opts = P_HEAD; 
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else begin
          ${b.var}_index_${b.lineno} <= 0;
          opts = P_TAIL; 
        end 
        %endif
      %endif 
    %endif ## se.storage_class
    outFifo.enq(tuple4(${address}, tagged T${se.typename} sendobj_val, ${out_vc}, opts));
    endaction 
  %if blocking:
    recv_synctoken(${address});
  %endif
  %if infer_loop:
    endseq
  %endif 
  ${EXIT_LOG(b=b)}
  %if use_half_pingpong:
  pingpong_${b.lineno} <= ~pingpong_${b.lineno};
%endif
 %endfor ## addresses... depth first sending
</%def>
##################################################################################################
<%def name="body_scatter(b)">
  ${ENTRY_LOG(b=b)}
  <%
    se = _tm.symbol_table[b.var]
    se = _tm.symbol_table[b.var]
    address_list = list(map(_am.taskmap, b.address_list))
    items_per_address = se.arraysize//len(address_list)
    out_vc = 0
  %>\
  %for chunk_index, address in enumerate(address_list):
      // repeat(${items_per_address})
      ${b.var}_index_${b.lineno} <= 0;
      while(${b.var}_index_${b.lineno} < ${items_per_address})
      seq
      par 

    %if se.storage_class == '__bram__':
      ${b.var}.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: (${chunk_index*items_per_address}+${b.var}_index_${b.lineno})});
    %elif se.storage_class == '__ram__':
      ${b.var}.readReq((${chunk_index*items_per_address}+${b.var}_index_${b.lineno}));
    %elif se.storage_class == '__mbus__':
      ${b.var}.readReq((${chunk_index*items_per_address}+${b.var}_index_${b.lineno}));
    %endif

     action
     SendXOpt opts = P_NONE; // TODO LongTrain packets still WIP so this will be ignored
       %if se.storage_class == '__fifo__':
           NOTE scattering a FIFO not yet supported
       %elif se.storage_class == '__bram__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
           let sendobj_val <- ${b.var}.portA.response.get; //suv
         %endif 
       %elif se.storage_class == '__ram__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
             let sendobj_val <- ${b.var}.readRsp(); //suv
         %endif 
       %elif se.storage_class == '__mbus__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
             let sendobj_val <- ${b.var}.readRsp(); //suv
         %endif 
       %elif se.storage_class == '__reg__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
           let sendobj_val = ${b.var}.sub(${chunk_index*items_per_address}+${b.var}_index_${b.lineno});
         %endif 
       %endif ## se.storage_class
       outFifo.enq(tuple4(${address}, tagged T${se.typename} sendobj_val, ${out_vc}, opts));
       
       ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
       endaction 
      endpar 
     endseq // repeat
  %endfor
  ${EXIT_LOG(b=b)}
</%def>
##################################################################################################

##################################################################################################
<%def name="body_scatter_old(b)">
  ${ENTRY_LOG(b=b)}
  <%
    se = _tm.symbol_table[b.var]
    se = _tm.symbol_table[b.var]
    address_list = list(map(_am.taskmap, b.address_list))
    items_per_address = se.arraysize//len(address_list)
    out_vc = 0
  %>\
  %for chunk_index, address in enumerate(address_list):
     repeat(${items_per_address})
     seq

    %if se.storage_class == '__bram__':
      ${b.var}.portA.request.put(BRAMRequest{write: False, responseOnWrite: False, address: (${chunk_index*items_per_address}+${b.var}_index_${b.lineno})});
    %elif se.storage_class == '__ram__':
      ${b.var}.readReq((${chunk_index*items_per_address}+${b.var}_index_${b.lineno}));
    %elif se.storage_class == '__mbus__':
      ${b.var}.readReq((${chunk_index*items_per_address}+${b.var}_index_${b.lineno}));
    %endif

     action
       %if se.storage_class == '__fifo__':
           NOTE scattering a FIFO not yet supported
       %elif se.storage_class == '__bram__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
           let sendobj_val <- ${b.var}.portA.response.get; //suv
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
         %endif 
       %elif se.storage_class == '__ram__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
             let sendobj_val <- ${b.var}.readRsp(); //suv
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
         %endif 
       %elif se.storage_class == '__mbus__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
             let sendobj_val <- ${b.var}.readRsp(); //suv
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
         %endif 
       %elif se.storage_class == '__reg__':
         %if se.arraysize == 1:
           // scattering 1 item not supported
         %else:
           let sendobj_val = ${b.var}.sub(${chunk_index*items_per_address}+${b.var}_index_${b.lineno});
           if (${b.var}_index_${b.lineno} < ${items_per_address-1})
             ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
           else 
             ${b.var}_index_${b.lineno} <= 0;
         %endif 
       %endif ## se.storage_class
       outFifo.enq(tuple4(${address}, tagged T${se.typename} sendobj_val, ${out_vc}, 0));
     endaction 
     endseq // repeat
  %endfor
  ${EXIT_LOG(b=b)}
</%def>
##################################################################################################
<%def name="body_kernel_call(b)">
  ${ENTRY_LOG(b,True)}
  ${b.stmtuniq_tag}${_tm._gam.hwkernelname2modname(b.kernel_name)}.start();
  await(${b.stmtuniq_tag}${_tm._gam.hwkernelname2modname(b.kernel_name)}.done());
  ${EXIT_LOG(b,True)}
</%def>
##################################################################################################
##################################################################################################
<%def name="fsmstmt_gen_immediate_blocks(bl, nested=False)">
%for b in bl:
  %if nested:
    seq //${b.stmtuniq_tag}                                    
    ${EV_TS_TOP(b=b)}
  %else:
    Stmt ${b.stmtuniq_tag} = seq 
    ${EV_TS_TOP(b=b)}
  %endif 
  ############################# loop_block // repeat variety
  %if b.name == 'loop_block':
    %if b.has_loopindex:  ## loop index specs
    <%
      li = b.children[0]
    %>
    for(loopidx_${li.index_var} <= ${li.start_index};  loopidx_${li.index_var} < ${li.max_index}; loopidx_${li.index_var}<=  loopidx_${li.index_var}+${li.index_incr}) seq
        ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
      endseq 

    %elif b.repeatcount == -1:
      while(True) seq 
        ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
      endseq 
    %else:
  <%doc>
      repeat(${b.repeatcount}) 
      seq
        ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
      endseq // repeat(${b.repeatcount})
  </%doc>
      repeatcount_${b.stmtuniq_tag} <= 0;
      while(repeatcount_${b.stmtuniq_tag} < ${b.repeatcount}) seq
        ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
        repeatcount_${b.stmtuniq_tag} <= repeatcount_${b.stmtuniq_tag} + 1;
      endseq 
    %endif 
  %endif
  ############################# parallel_block
  %if b.name == "parallel_block":
    par // parallel-------------------------------------------------------------------------------------
     ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
    endpar // endparallel-------------------------------------------------------------------------------
  %endif 
  ############################# group_block
  %if b.name == "group_block":
    seq // group
     ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
    endseq // endgroup
  %endif 
  ############################# 
  %if b.name == "displaystmt":
    ${body_display(b=b)}
  %endif 
  ############################# 
  %if b.name == "mcopy":
    ${body_mcopy(b=b)}
  %endif 
  ############################# 
  %if b.name == "halt":
    ${body_halt(b=b)}
  %endif 
  ############################# 
  %if b.name == "recv":
    ${body_recv(b=b)}
  %endif 
  ############################# 
  %if b.name == "gather":
      ${body_gather(b=b)}
  %endif 
  ############################# 
  %if b.name == "send":
    ${body_send(b=b)}
  %endif 
  ############################# 
  %if b.name == "broadcast":
    ${body_broadcast(b=b)}
  %endif 
  ############################# 
  %if b.name == "barrier":
    ${body_barrier(b=b)}
  %endif 
  ############################# 
  %if b.name == "scatter":
    ${body_scatter(b=b)}
  %endif 
  ############################# 
  %if b.name == "delaystmt":
    ${body_delay(b=b)}
  %endif 
  ############################# 
  %if b.name == "kernel_call":
    ${body_kernel_call(b=b)}
  %endif 
  ############################# 
  %if nested:
    ${EV_TS_BOTTOM(b=b)}
    endseq  //${b.stmtuniq_tag} 
  %else: 
    ${EV_TS_BOTTOM(b=b)}
    endseq; //${b.stmtuniq_tag} 
  %endif 
%endfor 
</%def>
##################################################################################################
##################################################################################################
<%def name="compose_stmtfsm_instances(bl)">
  %for b in bl:
    ##${EV_TS_TOP(b=b)}
    ${b.stmtuniq_tag};
    ##${EV_TS_BOTTOM(b=b)}
  %endfor 
</%def>
##################################################################################################
##################################################################################################
<% 
top_bl = _tm.get_immediate_blocks() 
%>\
${fsmstmt_gen_immediate_blocks(bl=top_bl)}
Stmt top = seq 
noAction;
%if top_bl:
    while(True) seq //implicit loop
    ## dtlogger.trace($format("ev_ts: top; lvl: ${top_bl[0].depth}; lno: ${top_bl[0].lineno}"));
    ${compose_stmtfsm_instances(bl=top_bl)}
    ## dtlogger.trace($format("ev_ts: bottom; lvl: ${top_bl[-1].depth}; lno: ${top_bl[-1].lineno}"));
    endseq
%endif 
endseq;

mkAutoFSM(top);
##################################################################################################
##################################################################################################
## vim: ft=mako
