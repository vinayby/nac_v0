<%include file='Banner.mako' args="_am=_am"/>
package NATypes;
  import NTypes::*;
  import Vector::*;
  import DefaultValue::*;
  import RegFile::*;
  <%
  params = _am.psn.params
  type_table = _am.type_table
  max_msg_object_size = _am.get_max_parcel_size()
  %>

//-----------------------------------------------------------------------------
// Appication Specific Definitions
//-----------------------------------------------------------------------------

typedef enum {IDLE, RUNNING, FINISH} KState deriving (Eq, Bits); 

%for k, v in type_table.items():
  typedef struct {
  %for kk, vv, az in v.member_info_tuples:
    %if az == 1:
      Bit#(${vv}) ${kk};
    %else:
      Vector#(${az}, Bit#(${vv})) ${kk};
    %endif 
    %endfor
  } ${k} deriving(FShow);
  //
  // instance for type ${k}
  //
    instance DefaultValue#(${k});
       defaultValue = ${k} {
         ${':defaultValue, '.join([mn for mn,mz,az in v.member_info_tuples])}:defaultValue
      };
    endinstance 
    <%
      (nFlits, items) = _am.get_struct_member_index_ranges_wrt_flitwidth(k)
      ty_size = _am.get_type_size_in_bits(k)
    %>
    instance Bits#(${k}, ${ty_size});
      function Bit#(${ty_size}) pack(${k} x);
         Bit#(${ty_size}) d = 0; 
      %for i,(epos, spos, vname, az) in enumerate(items):
         d[${epos}:${spos}] = pack(x.${vname});
      %endfor 
         return d;
      endfunction
      function ${k} unpack(Bit#(${ty_size}) x);
        return ${k} {
        <%
          (nFlits, items) = _am.get_struct_member_index_ranges_wrt_flitwidth(k)
        %>\
        %for i,(epos, spos, vname, az) in enumerate(items):
            %if az > 1:
             ${vname} : toChunks(x[${epos}:${spos}])\
            %else:
             ${vname} : (x[${epos}:${spos}])\
            %endif 
          %if i < len(items)-1:
,
          %endif
        %endfor
        };
      endfunction 
    endinstance 

%endfor

<%
  disp_recep_types_already_generated=dict()
%>
%for k in range(0, len(_am.tmodels)):
<%
  _tm = _am.tmodels[k]
  _task_name = 'Task_'+ _tm.taskname 
  _taskdef_name = 'Task_'+ _tm.taskdefname 
  if not _tm.is_task_instance():
    _taskdef_name = _task_name
  incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
  outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]
  sources = _tm.resolve_source_names_(_tm.get_unique_message_sources())
  import pdb
%>
##    GENERATE ONLY ONCE PER TASKDEF BEGIN
%if _taskdef_name not in disp_recep_types_already_generated:
//task ${_taskdef_name} INCOMING ${_tm.get_list_of_types_incoming_and_outgoing()[0]}
//task ${_taskdef_name} OUTGOING ${_tm.get_list_of_types_incoming_and_outgoing()[1]}
%if incoming_types:
  typedef union tagged {
%for t in incoming_types:
    ${t} T${t}; //type tag # ${_am.typename2tag(t)}
%endfor
} ReceptionUnion${_taskdef_name} deriving(Bits, FShow);
%endif

%if outgoing_types:
  typedef union tagged {
%for t in outgoing_types:
    ${t} T${t}; //type tag # ${_am.typename2tag(t)}
%endfor
} DispatchUnion${_taskdef_name} deriving(Bits, FShow);
%endif
%if incoming_types:
  typedef Tuple3#(SourceAddr, ReceptionUnion${_taskdef_name}, Bit#(4))  ReceptionUnion${_taskdef_name}_tuple;
  function ReceptionUnion${_taskdef_name}_tuple taggedTypeIn${_taskdef_name} (FlitHeaderPayLoad h);
  case (h.ttag) 
    %for t in incoming_types:
      ${_am.typename2tag(t)} : return tuple3(  h.srcaddr, tagged T${t} defaultValue, 0); 
    %endfor 
  endcase
endfunction
%endif
%if outgoing_types:
  typedef Tuple4#(DestAddr, DispatchUnion${_taskdef_name}, VCType, SendXOpt)  DispatchUnion${_taskdef_name}_tuple;
  function DispatchUnion${_taskdef_name}_tuple taggedTypeOut${_taskdef_name} (FlitHeaderPayLoad h, VCType out_vc, SendXOpt opts);
  case (h.ttag) 
    %for t in outgoing_types:
      ${_am.typename2tag(t)} : return tuple4(h.srcaddr, tagged T${t} defaultValue, out_vc, opts);
    %endfor 
  endcase
endfunction
%endif
## For fully specified tasks only
%if sources and not _tm.is_task_instance():
  function Integer dict${_task_name}_srcaddr_to_zeroidx(Tuple2#(DestAddr , SourceAddr ) nodeid_srcaddr);
  case(nodeid_srcaddr)
    %for idx, s in enumerate(sources):
      tuple2(${_am.taskmap(_tm.taskname)}, ${s}) : return ${idx};
    %endfor
  endcase 
  endfunction
%endif 

##---NESTEDtestBEGIN
## IMPL _am.all_instances_of_type(_tm); return list of _tm's 
%if sources and _tm.is_task_instance(): ## AAA
function Integer dict${_taskdef_name}_srcaddr_to_zeroidx(Tuple2#(DestAddr , SourceAddr ) nodeid_srcaddr);
case(nodeid_srcaddr)
%for _tm1 in _am.all_instances_of_type(_tm):
<%
  sources1 = _tm1.resolve_source_names_(_tm1.get_unique_message_sources())
%>
%if sources1:
    %for idx, s in enumerate(sources1):
      tuple2(${_am.taskmap(_tm1.taskname)}, ${s}) : return ${idx};
    %endfor
  %endif    
%endfor ## pass-2
  endcase 
endfunction
%endif ## AAA
##---NESTEDtestEND

<% disp_recep_types_already_generated[_taskdef_name] = True %>

%endif ## disp_recep_types_already_generated
##    GENERATE ONLY ONCE PER TASKDEF END
//
// ${_task_name} specific data-type-conversion functions could be
// placed here, but FORNOW, let them be within their module contexts.
// 
%endfor ## pass-1

// A common dictionary for when the number of actual tasks less than
// the number of available node places on the network
function Integer dict_srcaddr_to_zeroidx(SourceAddr src);
case(src)
%for k,_tm in enumerate(_am.tmodels):
  ${_am.taskmap(_tm.taskname)}: return ${k};
 %endfor
endcase 
endfunction 

// task array instances
%for tiu in _am.tinstances_unexpanded:
  <%
    import pdb
    #pdb.set_trace()
    if tiu.num_task_instances:
      tasknamelist = ['{}_{}'.format(tiu.taskname, e) for e in range(tiu.num_task_instances)]
    else:
      continue 
    address_list = list(map(_am.taskmap, tasknamelist))
    import math
    indexwidth = int(math.ceil(math.log(len(address_list), 2)))
  %>
  function SourceAddr grp_${tiu.taskname}(Bit#(16) index);
  Bit#(${indexwidth}) index_ = truncate(index);
  case(index_)
  %for i, a in enumerate(address_list):
    ${i} : return ${a};
  %endfor 
  endcase 
  endfunction 
%endfor 

<%doc> ALL tasks common dictionary
## For separate instances
%if _tm.is_task_instance(): ## AAA
function Integer dict_srcaddr_to_zeroidx(Tuple2#(DestAddr , SourceAddr ) nodeid_srcaddr);
case(nodeid_srcaddr)
%for k in range(0, len(_am.tmodels)):
<%
  _tm = _am.tmodels[k]
  _task_name = 'Task_'+ _tm.taskname 
  _taskdef_name = 'Task_'+ _tm.taskdefname 
  if not _tm.is_task_instance():
    _taskdef_name = _task_name
  incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
  outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]
  #sources = [_am.taskmap(s) for s in _tm.get_unique_message_sources() if _am.taskmap(s) is not None]
  sources = _tm.resolve_source_names_(_tm.get_unique_message_sources())
%>
%if sources:
    %for idx, s in enumerate(sources):
      tuple2(${_am.taskmap(_tm.taskname)}, ${s}) : return ${idx};
    %endfor
  %endif    
%endfor ## pass-2
  endcase 
endfunction
%endif ## AAA
</%doc>
endpackage
## vim: ft=mako

