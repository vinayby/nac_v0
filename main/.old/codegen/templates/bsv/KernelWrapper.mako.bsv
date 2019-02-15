<%! from time import strftime as time %>
<% 
if v_params:
  comma_sep_v_param_list = '#('+', '.join(['parameter '+ty+' '+inst for ty,inst in v_params]) +')'
else: 
  comma_sep_v_param_list = ''
generate_bvi_wrapper = False
if '__vivado_ap_none__' in qualifiers:
  generate_bvi_wrapper = True
collect_names_for_scheduling = []
%>\
// 
// Kernel PE Wrapper Generated at ${time('%Y/%m/%d %H:%M')}
// Can FILL-IN the details in BSV (it won't be overwritten on re-run)
//   
import DefaultValue::*;
import NATypes::*;
%if  generate_bvi_wrapper:
/// BVI 
interface ${'I'+modname}_vivado_ap_none;
  method Action start();
  method Bool isReady();
  method Bool isIdle();
  method Bool isDone();
// inputs
  %for (inst, ty) in iargs:
  %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name = m_name+'_V' if m_size > 32 else m_name %>
    (* always_ready *)
  method Action put_${inst}_${m_name}(Bit#(${m_size}) ${m_name});
    <% collect_names_for_scheduling.append('_'.join(['put', inst, m_name]))  %>\
  %endfor
  %endfor
// what were marked statereg's in .na
  %for (inst, ty) in stateregs:
  %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name = m_name+'_V' if m_size > 32 else m_name %>
    (* always_ready *)
  method Action put_${inst}_${m_name}(Bit#(${m_size}) ${m_name});
    <% collect_names_for_scheduling.append('_'.join(['put', inst, m_name]))  %>\
  %endfor
  %endfor
// outputs 
  %for (inst, ty) in oargs:
  %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name = m_name+'_V' if m_size > 32 else m_name %>
  method Bit#(${m_size}) get_${inst}_${m_name}();
    <% collect_names_for_scheduling.append('_'.join(['get', inst, m_name]))  %>\
  %endfor
  %endfor

endinterface
import "BVI" ${pd_.name}_0 =  
module mk${modname}_vivado_ap_none(${'I'+modname}_vivado_ap_none);
  default_clock clk;
  default_reset rst_RST_N;
  input_clock clk (ap_clk)  <- exposeCurrentClock;
  input_reset rst_RST_N (ap_rst_n) clocked_by(clk) <- exposeCurrentReset;

  method start() enable(ap_start);
  method ap_idle  isIdle();
  method ap_done  isDone();
  method ap_ready isReady();
  //inputs
  %for (inst, ty) in iargs:
  %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name = m_name+'_V' if m_size > 32 else m_name %>
  method put_${inst}_${m_name}(${inst}_${m_name}) enable((*inhigh*) ignore00${inst}${m_name});
  %endfor
  %endfor
  //marked stateregs
  %for (inst, ty) in stateregs:
  %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name = m_name+'_V' if m_size > 32 else m_name %>
  method put_${inst}_${m_name}(${inst}_${m_name}) enable((*inhigh*) ignore00${inst}${m_name});
  %endfor
  %endfor

  %for (inst, ty) in oargs:
  %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name = m_name+'_V' if m_size > 32 else m_name %>
  method ${inst}_${m_name} get_${inst}_${m_name}() ready(ap_done);
  %endfor
  %endfor

  schedule  (
     start,
    isIdle,
    isDone,
    isReady,
    ${', '.join(collect_names_for_scheduling)}
  ) CF 
  (
     start,
    isIdle,
    isDone,
    isReady,
    ${', '.join(collect_names_for_scheduling)}
  );
endmodule 
%endif  


interface ${'I'+modname};
  %for (inst, typename) in stateregs:
     interface Put#(${typename}) ${inst}_in; 
%if not generate_bvi_wrapper:       ## pass in as normal input for bvi/vivado
     interface Get#(${typename}) ${inst}_out;
%endif
  %endfor 

  %for (inst, typename) in iargs:
     interface Put#(${typename}) ${inst}_in;
  %endfor
  %for (inst, typename) in oargs:
     interface Get#(${typename}) ${inst}_out;
     method Bool ${inst}_out_notEmpty();
  %endfor
endinterface


(* synthesize *)
module mk${modname}${comma_sep_v_param_list}(${'I'+modname});
  //in
  %for (inst, typename) in iargs:
   FIFOF#(${typename}) ${inst} <- mkFIFOF;
  %endfor
  //out
  %for (inst, typename) in oargs:
   FIFOF#(${typename}) ${inst} <- mkFIFOF;
 %endfor
 %for (inst, typename) in stateregs:
   FIFOF#(${typename}) ${inst}_i <- mkFIFOF;
   %if not generate_bvi_wrapper:
   FIFOF#(${typename}) ${inst}_o <- mkFIFOF;
   %endif 
 %endfor 

  //----------begin support logic ---------------
  %if generate_bvi_wrapper:
    let w${modname} <-  mk${modname}_vivado_ap_none;
  rule r1;
    w${modname}.start();
    //input
    %for (inst, ty) in iargs:
      ${inst}.deq;
     %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name_vivado = m_name+'_V' if m_size > 32 else m_name %>
       w${modname}.put_${inst}_${m_name_vivado}(${inst}.first.${m_name});
     %endfor 
    %endfor
    //statereg, marked
    %for (inst, ty) in stateregs:
    ${inst}_i.deq;
     %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name_vivado = m_name+'_V' if m_size > 32 else m_name %>
       w${modname}.put_${inst}_${m_name_vivado}(${inst}_i.first.${m_name});
     %endfor 
    %endfor
    //statereg, marked

  endrule 

  rule r2;
    %for (inst, ty) in oargs:
    ${ty} ret${inst};
     %for m_name, m_size in om_.struct_types_dict[ty].mnz_pairs:
  <% m_name_vivado = m_name+'_V' if m_size > 32 else m_name %>
       ret${inst}.${m_name} =  w${modname}.get_${inst}_${m_name_vivado}();
     %endfor
     ${inst}.enq(ret${inst});
    %endfor
  endrule 
  %endif ## generate_bvi_wrapper 
 
  %if om_.args.dummypes:
    rule r1;
      //in
  %for (inst, typename) in iargs:
   ${inst}.deq;
  %endfor
  //out
  %for (inst, typename) in oargs:
   ${inst}.enq(defaultValue);
  %endfor
 %for (inst, typename) in stateregs:
   ${inst}_i.deq;
   %if not generate_bvi_wrapper:
   ${inst}_o.enq(defaultValue);
   %endif 
 %endfor 

    endrule 
  %endif 
  //----------end support logic ------------------

  %for (inst, typename) in iargs:
   interface ${inst}_in = toPut(${inst});
  %endfor
  %for (inst, typename) in oargs:
   interface ${inst}_out  = toGet(${inst});
    method Bool ${inst}_out_notEmpty();
      return ${inst}.notEmpty();
    endmethod
 %endfor
 %for (inst, typename) in stateregs:
   interface ${inst}_in = toPut(${inst}_i);
     %if not generate_bvi_wrapper:
   interface ${inst}_out = toGet(${inst}_o);
     %endif
 %endfor 

endmodule
## vim: ft=mako
