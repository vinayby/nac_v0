<%include file='Banner.mako' args="om=om"/>
<%!
  import pdb
  import os
%>\
package Tasks;
  import NATypes::*;
  import CnctBridge::*;
  import FIFO::*;
  import FIFOF::*;
  import Connectable::*;
  import GetPut::*;
  import Vector::*;
  import StmtFSM::*;
  import Assert::*;
  import DefaultValue::*;
  import RegFile::*;
  import KernelLib::*;

  %if om.args.simverbosity == 'state-exit':
 `define DEBUGPRINTS1
%endif 
%if om.args.simverbosity == 'state-entry-exit':
 `define DEBUGPRINTS0
 `define DEBUGPRINTS1
%endif 
%if om.args.simverbosity == 'to-from-network':
 `define DEBUGPRINTS2
// `define DEBUGPRINTS3
%endif
%if om.args.simverbosity == 'send-recv-trace':
 `define INSTRUMENT_PRINTS
%endif

%for k in range(0, len(om.tm_list)): ## FOR1 TOP iteration over all tasks
 <% 
 _tm = om.tm_list[k]
 _task_name = 'Task_'+ _tm.get_task_name()
 incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
 outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]
 %>

 %if not _tm.is_marked_off_chip(): ## IF_NOT_OFF_CHIP
//-----------------------------------------------------------------------------
//          FromNetwork/${_task_name}, ToNetwork/${_task_name} 
//          Packet/${_task_name}, 
//          Task.*, mkTask.*, mkNodeTask.*
//-----------------------------------------------------------------------------

%if outgoing_types:
interface IToNetwork${_task_name};
  interface Put#(DispatchUnion${_task_name}_t3) putPacket;
  interface Vector#(NUM_VCS, Get#(Flit)) getFlit;
endinterface


(* synthesize *)
module mkToNetwork${_task_name} (IToNetwork${_task_name}); 
  FIFO#(DispatchUnion${_task_name}_t3) inFifo <- mkFIFO;
  Vector#(NUM_VCS, FIFO#(Flit)) outFifo <- replicateM(mkSizedFIFO(${max(2, _tm.num_flits_in_dispatch_union())}));
  Vector#(${int(om.get_max_packet_size()/int(om.params['FLIT_DATA_WIDTH']))}, Reg#(FlitData)) vflits <- replicateM(mkReg(0));
  Reg#(Bit#(16)) flits2send <- mkReg(0);
  Reg#(Bit#(16)) f_idx <- mkReg(0);
  Reg#(DestAddr) dstaddr <- mkRegU;
  Reg#(VCType) outvc <- mkRegU;
  Reg#(int) cticks <- mkReg(0); //local
  rule ticktock;
    cticks <= cticks + 1;
  endrule 

  <%doc>
 //NEW packers
 %for t in _tm.get_namelist_of_types():
 function Bit#(${om.get_max_packet_size()}) from${t}(${t} f);
   Bit#(${om.get_max_packet_size()}) d = 0; //same as in NATypes.bsv
  <%
    (nFlits, items) = om.new_get_struct_member_index_ranges_wrt_flitwidth(t)
  %>
  %for i,(epos, spos, vname) in enumerate(items):
    d[${epos}:${spos}] = f.${vname};
  %endfor 
   return d;
 endfunction
 %endfor
 </%doc>
  rule r_first (flits2send == 0);
    //stage msg flits to send
    FlitData d = 0;
    //source_address
    d[${om.getranges_tag_and_sourceaddr_info_in_flit()[1]}] = ${_tm.mapped_to_node};
    let p = inFifo.first; inFifo.deq;
    match {.dst_addr, .taggedtype, .out_vc} = p;
    dstaddr <= dst_addr;
    outvc <= out_vc;
    %if outgoing_types:
    case (taggedtype) matches
      %for t in outgoing_types:
      tagged T${t} .obj: begin 
          flits2send <= ${om.get_flits_in_type(t)};
          Vector#(${int(om.get_max_packet_size()/int(om.params['FLIT_DATA_WIDTH']))}, FlitData) vf_ = toChunks(pack(obj));
          writeVReg(vflits, vf_);
          d[${om.getranges_tag_and_sourceaddr_info_in_flit()[0]}] = ${om.typename2tag(t)};
  `ifdef INSTRUMENT_PRINTS
  $display("EVENTTRACE %d ${_tm.get_task_name()} send-out %d:%0d ${om.get_flits_in_type(t)} vc=%d", cticks, d[${om.getranges_tag_and_sourceaddr_info_in_flit()[1]}], dst_addr, out_vc);
  `endif 
  `ifdef DEBUGPRINTS2
          ## $display("ToNetwork ${_task_name} ${t} %d -> %d ${om.get_flits_in_type(t)} flits2send @ %t", d[${om.getranges_tag_and_sourceaddr_info_in_flit()[1]}], dst_addr, $time);
          $display("ToNetwork ${_task_name} ${t} %d -> %d ${om.get_flits_in_type(t)}, @ tick=%d \tmessage=", d[${om.getranges_tag_and_sourceaddr_info_in_flit()[1]}], dst_addr, cticks, fshow(p));
  `endif
                         end 
      %endfor
      default: $display("**** NO MATCH **** ToNetwork ${_task_name}");
    endcase
    %endif
    // send the first flit with (tag, source_addr)
    outFifo[outvc].enq(Flit{valid:1, is_tail:0, destAddr:dst_addr, vc:out_vc, data:d});
    `ifdef DEBUGPRINTS3
    $display("\t\t first flit (tonetwork)=", fshow( Flit{valid:1, is_tail:0, destAddr:dst_addr, vc:out_vc, data:d}  ));
    `endif 
  endrule 

  rule r_rest ( !(flits2send == 0) );
    Bit#(1) is_tail = 0;
    if (flits2send == 1) begin
      is_tail = 1;
      f_idx <= 0;
    end else f_idx <= f_idx + 1;
    flits2send <= flits2send - 1;
    int idx = unpack(zeroExtend(pack(f_idx)));
    let xdata = readReg(vflits[idx]);
    outFifo[outvc].enq(Flit{valid:1, is_tail:is_tail, destAddr:dstaddr, vc:outvc, data:xdata});
    `ifdef DEBUGPRINTS3
    $display("\t\t  main flits (tonetwork)=", fshow( Flit{valid:1, is_tail:is_tail, destAddr:dstaddr, vc:outvc, data:xdata}  ));
    `endif 
  endrule 
  
  Vector#(NUM_VCS, Get#(Flit)) getFlitV = newVector;
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    getFlitV[i] = toGet(outFifo[i]);
  end
  interface putPacket = toPut(inFifo); 
  interface getFlit = getFlitV;

endmodule 

%endif ## if there are outgoing_types 

%if incoming_types:
interface IFromNetwork${_task_name}; 
  interface Vector#(NUM_VCS, Put#(Flit)) putFlit;
  //method ActionValue#(ReceptionUnion${_task_name}_t2) getPacketFromSource(DestAddr d);
  interface Vector#(${len(_tm.get_unique_message_sources())}, Get#(ReceptionUnion${_task_name}_t2)) getPacket; 
endinterface 

(* synthesize *)
module mkFromNetwork${_task_name} (IFromNetwork${_task_name}); 
Vector#(NUM_VCS, FIFOF#(Flit)) inFifo <- replicateM(mkFIFOF);
Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_task_name}_t2)) outFifo <- replicateM(mkFIFO()); //sz
//Vector#(NUM_VCS, FIFO#(ReceptionUnion${_task_name}_t2)) outFifo <- replicateM(mkFIFO()); //sz
//Vector#(${len(_tm.get_unique_message_sources())}, Reg#(ReceptionUnion${_task_name}_t2)) staging <- replicateM(mkRegU);
Vector#(NUM_VCS, Reg#(ReceptionUnion${_task_name}_t2)) staging <- replicateM(mkRegU);
Vector#(NUM_VCS, Reg#(Bit#(8))) fc <- replicateM(mkReg(0)); // 
                                 ## TODO fc width as per buffer-depth-etc
  Reg#(int) cticks <- mkReg(0); //local
  rule ticktock;
    cticks <= cticks + 1;
  endrule 
  <%doc>
 //NEW pack'ers
 %for t in _tm.get_namelist_of_types():
 function Bit#(${om.get_max_packet_size()}) from${t}(${t} f);
   Bit#(${om.get_max_packet_size()}) d = 0; //same as in Defs.bsv
  <%
    (nFlits, items) = om.new_get_struct_member_index_ranges_wrt_flitwidth(t)
  %>
  %for i,(epos, spos, vname) in enumerate(items):
    d[${epos}:${spos}] = f.${vname};
  %endfor 
   return d;
 endfunction
 %endfor
 </%doc>
// NEW unpack'ers
%for t in _tm.get_namelist_of_types():
  function ${t} updateObj${t}(${t} obj, FlitData d, int flit_index);
    Vector#(${int(om.get_max_packet_size()/int(om.params['FLIT_DATA_WIDTH']))}, FlitData) vf = toChunks(pack(obj));
    vf[flit_index]  = d;
    return unpack(pack(vf));
  endfunction
%endfor


  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
rule pack;
  let f = inFifo[i].first; inFifo[i].deq;
  if (f.is_tail == 1)  fc[i] <= 0;
  else                 fc[i] <= fc[i] + 1;
  
  ReceptionUnion${_task_name}_t2 staging_next = staging[i];
  match {.src_addr, .taggedtype} = staging_next;

  if (fc[i] == 0) begin // first flit holds: (tag_id, src_addr), no msg
    let x = taggedTypeIn${_task_name}(f.data);
    staging[i] <= x;
    `ifdef DEBUGPRINTS3
    match {.src_addr_dbg, .taggedtype_dbg} = x;
    %if incoming_types:
      case (taggedtype_dbg) matches
        %for t in incoming_types:
        tagged T${t} .obj: begin 
        $display("\tFromNetwork ${_task_name} ${t} %d -> ${_tm.mapped_to_node} FlitZERO (0 of ${om.get_flits_in_type(t)}) @ tick=%d\t", src_addr_dbg, cticks, fshow(f));
                           end  
        %endfor
        
        default: $display("**** NO MATCH **** FromNetwork ${_task_name}");
      endcase
    %endif ## incoming types
    `endif
    
    `ifdef INSTRUMENT_PRINTS
  %if incoming_types:
    match {.src_addr_inst, .taggedtype_inst} = x;
      case (taggedtype_inst) matches
        %for t in incoming_types:
        tagged T${t} .obj: begin 
        $display("EVENTTRACE %d ${_tm.get_task_name()} recv-buffer %d:${_tm.mapped_to_node} ${om.get_flits_in_type(t)}", cticks, src_addr_inst);
                           end  
        %endfor
      endcase
    %endif ## incoming types

  `endif 

  end 
  else begin
    %if incoming_types:
    case (taggedtype) matches
      %for t in incoming_types:
      tagged T${t} .obj: begin 
        let obj1 = updateObj${t}(obj, f.data, unpack(zeroExtend(pack(fc[i]-1)))); 
        staging_next = tuple2(src_addr, tagged T${t} obj1);
  `ifdef DEBUGPRINTS2
          $display("\tFromNetwork ${_task_name} ${t} %d -> ${_tm.mapped_to_node} Flit (%d of ${om.get_flits_in_type(t)}) @ tick=%d\t", src_addr, fc[i], cticks, fshow(f));
  `endif
                         end 
      %endfor
      
      default: $display("**** NO MATCH **** FromNetwork ${_task_name}");
    endcase
    %endif ## incoming types
    if (f.is_tail == 1) 
      outFifo[ fromInteger(dict${_task_name}_srcaddr_to_zeroidx(src_addr)) ].enq(staging_next);
    else 
      staging[i] <= staging_next;
  end 
endrule 
end // end for over NUM_VCS
  Vector#(NUM_VCS, Put#(Flit)) putFlitV = newVector;
  Vector#(${len(_tm.get_unique_message_sources())}, Get#(ReceptionUnion${_task_name}_t2)) getPacketV = newVector; 
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    putFlitV[i] = toPut(inFifo[i]); 
  end
  for(Integer i=0; i<${len(_tm.get_unique_message_sources())}; i=i+1) begin
    getPacketV[i] = toGet(outFifo[i]);
  end

  interface putFlit = putFlitV;
  interface getPacket = getPacketV;
endmodule 
%endif ## if there are incoming types


interface ${_task_name};
  interface Vector#(${len(_tm.get_unique_message_sources())}, Put#(ReceptionUnion${_task_name}_t2)) putPacket;
	interface Get#(DispatchUnion${_task_name}_t3) getPacket;		
endinterface

##%for pepath in _tm.get_kernel_pe_paths():
##`ifndef ${os.path.basename(pepath).upper()[0:-4]}_BSV
##`define ${os.path.basename(pepath).upper()[0:-4]}_BSV
##`include "${pepath}"
##`endif
##%endfor 
(* synthesize *)   
module mk${_task_name}(${_task_name});
	Vector#(${len(_tm.get_unique_message_sources())}, FIFOF#(ReceptionUnion${_task_name}_t2)) inFifo  <- replicateM(mkFIFOF());
  FIFO#(DispatchUnion${_task_name}_t3) outFifo <- mkSizedFIFO(${max(2, len(outgoing_types))});
  Reg#(SourceAddr) saved_source_address <- mkRegU;
  FIFO#(Bit#(${len(_tm.get_unique_message_sources())})) idxof_only_fifo_with_data <- mkFIFO;
  Reg#(int) cticks <- mkReg(0); //local
  rule ticktock;
    cticks <= cticks + 1;
  endrule 
`ifdef 0 //crude, fix later
  //Reg#(Maybe#(Bit#(${len(_tm.get_unique_message_sources())}))) <- mkReg(tagged Invalid); 
  for(Integer i=0; i<${len(_tm.get_unique_message_sources())}; i=i+1) begin
    (* mutually_exclusive = "r_index_only_fifo_with_data" *)
    rule r_index_only_fifo_with_data (inFifo[i].notEmpty);
          idxof_only_fifo_with_data.enq(fromInteger(i));
    endrule 
  end //for
`endif
 
  <%include file='PEBody.mako.bsv' args="om=om,tm=_tm,_task_name=_task_name,struct_types_dict=om.struct_types_dict"/>
  Vector#(${len(_tm.get_unique_message_sources())}, Put#(ReceptionUnion${_task_name}_t2)) putPacketV  = newVector;
  for(Integer j=0; j<${len(_tm.get_unique_message_sources())}; j=j+1) begin
    putPacketV[j] = toPut(inFifo[j]);
  end 
  interface putPacket = putPacketV;  
	interface getPacket = toGet(outFifo);
endmodule //mk${_task_name}


%endif ## END IF_NOT_OFF_CHIP

(* synthesize *)   
module mkNode${_task_name}#(parameter PortId portid)(NOCPort);
  let bridge <- mkCnctBridge();
%if not _tm.is_marked_off_chip():
  let pack <- mkFromNetwork${_task_name};
  let depack <- mkToNetwork${_task_name};
  let pe <- mk${_task_name}(); 
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    mkConnection(bridge.pePort[i].get, pack.putFlit[i].put);
    mkConnection(depack.getFlit[i].get, bridge.pePort[i].put);
  end
  // Packets by source to pe by source
  for(Integer j=0; j<${len(_tm.get_unique_message_sources())}; j=j+1) begin
    mkConnection(pack.getPacket[j].get, pe.putPacket[j].put);
  end
  // One packet at a time, from pe to be depack to network
  mkConnection(pe.getPacket, depack.putPacket);
%endif\

%if om.noc_uses_credit_based_flowcontrol():
	method getFlit = bridge.nocPort.getFlit;
	method putCredits = bridge.nocPort.putCredits;
	method setRecvFlit = bridge.nocPort.setRecvFlit;
	method getCredits = bridge.nocPort.getCredits;
	method setRecvPortID = bridge.nocPort.setRecvPortID;
%else:
	method getFlit = bridge.nocPort.getFlit;
	method setNonFullVC = bridge.nocPort.setNonFullVC;
	method setRecvFlit = bridge.nocPort.setRecvFlit;
	method getRecvVCMask = bridge.nocPort.getRecvVCMask;
	method setRecvPortID = bridge.nocPort.setRecvPortID;
%endif\

%if _tm.is_marked_off_chip():
	interface putFlitSoft = bridge.nocPort.putFlitSoft;
  interface getFlitSoft = bridge.nocPort.getFlitSoft;
  // essentially:
  // return bridge.nocPort;
%endif
endmodule

%endfor  ## ENDFOR1 TOP iteration over all tasks
endpackage
## vim: ft=mako



