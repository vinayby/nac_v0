<%include file='Banner.mako' args="om=om"/>
package NATypes;
  import Vector::*;
  import DefaultValue::*;
  import RegFile::*;
%if om.args.fpunits:
  import FPDef::*;
  import FPUModel::*;
  import FPUWrap::*;
%endif 
  <%
  params = om.params
  struct_types_dict = om.struct_types_dict
  %>
typedef ${params["NUM_USER_SEND_PORTS"]} NUM_NODES;
typedef TLog#(${params["NUM_USER_RECV_PORTS"]}) DEST_WIDTH;
typedef TMax#(TLog#(${params["NUM_VCS"]}),1) VC_WIDTH;
typedef ${params["NUM_USER_SEND_PORTS"]} NUM_USER_SEND_PORTS;
typedef ${params["NUM_USER_RECV_PORTS"]} NUM_USER_RECV_PORTS;
typedef ${params["NUM_VCS"]} NUM_VCS;
typedef ${params["FLIT_DATA_WIDTH"]} FLIT_DATA_WIDTH;
typedef ${params["FLIT_BUFFER_DEPTH"]} FLIT_BUFFER_DEPTH;

typedef Bit#(DEST_WIDTH) DestAddr;
typedef Bit#(VC_WIDTH) VCType;
typedef Bit#(FLIT_DATA_WIDTH) FlitData;
typedef Bit#(TSub#(FLIT_DATA_WIDTH, DEST_WIDTH)) FlitData_InclSrcAddr;
typedef Bit#(NUM_VCS) NF_VCMask;
typedef Bit#(TLog#(${params["NUM_USER_RECV_PORTS"]})) RecvPortId;
typedef DestAddr PortId;
typedef DestAddr SourceAddr;

// Flit without source
typedef struct {
	Bit#(1) valid;
	Bit#(1) is_tail;
	DestAddr destAddr;
	VCType vc;
	FlitData data;
} Flit deriving(Bits, FShow);

typedef TAdd#(TLog#(${params["FLIT_BUFFER_DEPTH"]}), 1) CreditCounterWidth;
typedef Bit#(CreditCounterWidth) CreditCounter;

typedef struct {
  Bit#(1) valid;
  VCType vc;
} Credit deriving(Bits, Eq);

//-----------------------------------------------------------------------------
// Appication Specific Definitions
//-----------------------------------------------------------------------------

typedef enum {IDLE, RUNNING, FINISH} KState deriving (Eq, Bits); 

%for k, v in struct_types_dict.items():
  typedef struct {
    %for kk, vv in v.mnz_pairs:
      Bit#(${vv}) ${kk};
    %endfor
  } ${k} deriving(FShow);
    instance DefaultValue#(${k});
     defaultValue = ${k} {
       ${':defaultValue, '.join([mn for mn,mz in v.mnz_pairs])}:defaultValue
     };
    endinstance 
    instance Bits#(${k}, ${om.get_max_packet_size()});
      function Bit#(${om.get_max_packet_size()}) pack(${k} x);
       Bit#(${om.get_max_packet_size()}) d = 0; 
    <%
      (nFlits, items) = om.new_get_struct_member_index_ranges_wrt_flitwidth(k)
    %>
    %for i,(epos, spos, vname) in enumerate(items):
      d[${epos}:${spos}] = x.${vname};
    %endfor 
     return d;
     endfunction
     function ${k} unpack(Bit#(${om.get_max_packet_size()}) x);
    return ${k} {
      <%
        (nFlits, items) = om.new_get_struct_member_index_ranges_wrt_flitwidth(k)
      %>\
      %for i,(epos, spos, vname) in enumerate(items):
          ${vname} : x[${epos}:${spos}]\
        %if i < len(items)-1:
,
        %endif
      %endfor
    };
     endfunction 
    endinstance 

%endfor


%for k in range(0, len(om.tm_list)):
<%
  _tm = om.tm_list[k]
  _task_name = 'Task_'+ _tm.get_task_name()
  incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
  outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]
  sources = [om.taskmap(s) for s in _tm.get_unique_message_sources() if om.taskmap(s) is not None]
%>

//task ${_task_name} INCOMING ${_tm.get_list_of_types_incoming_and_outgoing()[0]}
//task ${_task_name} OUTGOING ${_tm.get_list_of_types_incoming_and_outgoing()[1]}
%if incoming_types:
  typedef union tagged {
%for t in incoming_types:
    ${t} T${t}; //type tag # ${om.typename2tag(t)}
%endfor
  } ReceptionUnion${_task_name} deriving(Bits, FShow);
%endif

%if outgoing_types:
  typedef union tagged {
%for t in outgoing_types:
    ${t} T${t}; //type tag # ${om.typename2tag(t)}
%endfor
  } DispatchUnion${_task_name} deriving(Bits, FShow);
%endif
%if incoming_types:
typedef Tuple2#(SourceAddr, ReceptionUnion${_task_name})  ReceptionUnion${_task_name}_t2;
function ReceptionUnion${_task_name}_t2 taggedTypeIn${_task_name} (FlitData d);
  case (d[${om.getranges_tag_and_sourceaddr_info_in_flit()[0]}]) 
    %for t in incoming_types:
      ${om.typename2tag(t)} : return tuple2(truncate(d[${om.getranges_tag_and_sourceaddr_info_in_flit()[1]}]), tagged T${t} defaultValue); 
    %endfor 
  endcase
endfunction
%endif
%if outgoing_types:
typedef Tuple3#(DestAddr, DispatchUnion${_task_name}, VCType)  DispatchUnion${_task_name}_t3;
function DispatchUnion${_task_name}_t3 taggedTypeOut${_task_name} (FlitData d, VCType out_vc);
  case (d[${om.getranges_tag_and_sourceaddr_info_in_flit()[0]}]) 
    %for t in outgoing_types:
      ${om.typename2tag(t)} : return tuple3(truncate(d[${om.getranges_tag_and_sourceaddr_info_in_flit()[1]}]), tagged T${t} defaultValue, out_vc);
    %endfor 
  endcase
endfunction
%endif

%if sources:
function Integer dict${_task_name}_srcaddr_to_zeroidx(SourceAddr src_addr);
  case(src_addr)
    %for idx, s in enumerate(sources):
      ${s} : return ${idx};
    %endfor
  endcase 
endfunction
%endif 
//
// ${_task_name} specific data-type-conversion functions could be
// placed here, but FORNOW, let them be within their module contexts.
// 
%endfor
endpackage
## vim: ft=mako

