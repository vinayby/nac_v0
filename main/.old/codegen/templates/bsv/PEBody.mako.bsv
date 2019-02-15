<%page args="om,tm,_task_name,struct_types_dict"/>\
<%!
  import pdb 
  use_singleton_kern_instances = True
%>\


// Variable defs, as FIFOs
% for k, v in tm.vardefs.items():
  <%
    (typename, [[attrib, initfile]], array_size) = tm.find_typeinfo(k)
    import math
    width_arraysize = int(math.ceil(math.log(array_size, 2)))
  %>\
  %if tm.instance_has_attrib_state(k): 
      %if array_size == 1:
          Reg#(${typename}) ${k} <- mkReg(defaultValue);
      %else:
          //Vector#(${array_size},  Reg#(${typename})) ${k} <- replicateM(mkReg(defaultValue));
          Reg#(Bit#(${width_arraysize})) ${k}_indexcntr <- mkReg(0);
          %if initfile:
              RegFile#(Bit#(${width_arraysize}), ${typename}) ${k} <- mkRegFileLoad(${initfile}, 0, (${array_size-1}));
          %else:
              RegFile#(Bit#(${width_arraysize}), ${typename}) ${k} <- mkRegFile(0, (${array_size-1}));
          %endif 
      %endif     
  %else:
      %if array_size == 1:
          FIFOF#(${typename}) ${k} <- mkFIFOF; 
      %else:
          FIFOF#(${typename}) ${k} <- mkSizedFIFOF(${array_size}); 
      %endif     

  %endif 
% endfor
// Instantiating kernel PEs
%if use_singleton_kern_instances:
    %for modname in tm.get_kernel_modnames():
      let kern_${modname} <- mk${modname}(${tm.for_pebody_mako_get_kernel_ioargs(modname)});
    %endfor 
%else:
%for modname in tm.get_kernel_modnames():
  let kern_${modname} <- mk${modname}(${tm.get_v_param_assignment_string(modname)});
%endfor
%endif

<%def name="fsmstmt_gen_immediate_blocks(bl, nested=False)">
##--------------------------------------------------------------
%for b in bl:
 %if nested:
   seq //${b.name}_${b.depth}${bl.index(b)} 
 %else:
    Stmt ${b.name}_${b.depth}${bl.index(b)} = seq
  %endif 

%if b.name == "group":
         <%  imm_b_list = tm.get_immediate_blocks(b)   %>\
         seq // group
         ${fsmstmt_gen_immediate_blocks(bl=imm_b_list, nested=True)}
         endseq //end_group
%endif
 %if b.name == "parallel":
         <%  imm_b_list = tm.get_immediate_blocks(b)   %>\
        
         par // parallel
         ${fsmstmt_gen_immediate_blocks(bl=imm_b_list, nested=True)}
         endpar //endparallel
 %endif ## end parallel
\
\
    <%doc>
      LOOP stmt
    </%doc>
      %if b.name == "loop":
         <%  imm_b_list = tm.get_immediate_blocks(b)   %>\
        
          %if b.repeatcount == -1:
              while(True) seq
         ${fsmstmt_gen_immediate_blocks(bl=imm_b_list, nested=True)}
              endseq // while(True) LOOP 
          %else:
            repeat(${b.repeatcount}) 
            seq
         ${fsmstmt_gen_immediate_blocks(bl=imm_b_list, nested=True)}
            endseq //repeat(${b.repeatcount})
           %endif
      %endif
\
    %if b.name == "display":
      <% 
         (typename, attribs, array_size) = tm.find_typeinfo(b.var)
         (yes, repcount, xx) = tm.in_a_loop_context_are_we(b)
         #infer_implicit_loop = int(array_size) > 1 and not (yes and repcount > 1 and repcount <= int(array_size))
         infer_implicit_loop = int(array_size) > 1 # and not (repcount > 1 and repcount <= int(array_size))
      %>\
      %if infer_implicit_loop:
        repeat(${array_size})
        seq
      %endif 
\
        ## <% (fmtstr, vlstr) = tm.get_var_fmt_specs(b.children[0].var)  %>\
        ## $display(" display_${b.depth}${bl.index(b)}  ${tm.get_task_name()} ${fmtstr} [t=%t]", ${vlstr}, $time); 
        $display("[%d] display_${b.depth}${bl.index(b)}  ${tm.get_task_name()} instance=${b.children[0].var}\t", cticks, fshow(${b.children[0].var}), $time); 
        %if not tm.is_instance_alive(b.children[0].var, b.getpos()):
                ${b.children[0].var}.deq(); 
                // use: ${b.children[0].parentspos} alive? ${tm.is_instance_alive(b.children[0].var, b.getpos())}
        %endif
      %if infer_implicit_loop:
        endseq // repeat(${array_size})
      %endif 
\
    %endif 
\
\
    %if b.name == "delay":
      delay(${b.ccs});
    %endif 
\
  %if b.name == "recv":
      <% 
         (typename, attribs, array_size) = tm.find_typeinfo(b.var)
         (yes, repcount, xx) = tm.in_a_loop_context_are_we(b)
         #infer_implicit_loop = int(array_size) > 1 and not (yes and repcount > 1 and repcount <= int(array_size))
         infer_implicit_loop = int(array_size) > 1 # and not (repcount > 1 and repcount <= int(array_size))
      %>\
      %if infer_implicit_loop:
        repeat(${array_size})
        seq
      %endif 
\
      `ifdef DEBUGPRINTS0
      $display("[%d] STATE (enter) ${tm.get_task_name()}:\t recv_${b.depth}${bl.index(b)}", cticks);
      `else
      noAction;
      `endif 
        
        %if b.src_save_name:
        action
         let idx = idxof_only_fifo_with_data.first; idxof_only_fifo_with_data.deq;
         match {.src_addr, .taggedtype} = inFifo[idx].first; 
         let in_obj = taggedtype.T${typename};
         saved_source_address <= src_addr;
         `ifdef DEBUGPRINTS2
         $display("\t saved_source_address (for return) %d ", src_addr);
         `endif
         let typematch = False;
         if (taggedtype matches tagged T${typename} .v)
           typematch = True;
        if (!typematch)
         $display("TYPE mismatch (in ${tm.get_task_name()} @${b.depth}${bl.index(b)})");
           %if tm.instance_has_attrib_state(b.var):
                   ${b.var}._write((in_obj)); 
           %else:
                   ${b.var}.enq((in_obj)); 
           %endif
           inFifo[idx].deq; // def: ${b.children[0].parentspos} ${tm.is_instance_alive(b.var, b.getpos())} 
       `ifdef INSTRUMENT_PRINTS
       $display("EVENTTRACE %d ${tm.get_task_name()} recv-use %d:${tm.mapped_to_node}", cticks, src_addr);
       `endif
        endaction
\
        %else:
        action 
           let fifo_src_index = fromInteger(dict${_task_name}_srcaddr_to_zeroidx(${om.taskmap(b.src_list[0])}));
           match {.src_addr, .taggedtype} = inFifo[fifo_src_index].first; 
           let in_obj = taggedtype.T${typename}; // TODO: proper checks, even source_addr
           //print if at least 1 False
           let typematch = False;
           if (taggedtype matches tagged T${typename} .v)
             typematch = True;
           let srcmatch = src_addr == ${om.taskmap(b.src_list[0])};
           if (!typematch || !srcmatch) 
             $display("SRC/TYPE mismatch (in ${tm.get_task_name()} @${b.depth}${bl.index(b)}): (typematch=%d (${typename}), srcmatch=%d (got=%d, exp=%d))", typematch, srcmatch, src_addr, ${om.taskmap(b.src_list[0])});
           %if tm.instance_has_attrib_state(b.var):
               %if array_size  == 1:
                   ${b.var}._write((in_obj)); 
               %else:
                   ${b.var}.upd(${b.var}_indexcntr, in_obj);
                   if (${b.var}_indexcntr < ${array_size})
                      ${b.var}_indexcntr <= ${b.var}_indexcntr + 1;
                   else 
                      ${b.var}_indexcntr <= 0;
               %endif


           %else:
                   ${b.var}.enq((in_obj)); 
           %endif
              inFifo[fifo_src_index].deq; // def: ${b.children[0].parentspos} ${tm.is_instance_alive(b.var, b.getpos())}
       `ifdef INSTRUMENT_PRINTS
       $display("EVENTTRACE %d ${tm.get_task_name()} recv-use %d:${tm.mapped_to_node}", cticks, src_addr);
       `endif
         endaction 
        %endif
\
      `ifdef DEBUGPRINTS1
        $display("[%d] STATE (exit) ${tm.get_task_name()}:\t recv_${b.depth}${bl.index(b)}", cticks);
      `endif 
      %if infer_implicit_loop:
          endseq // repeat(${array_size}) for recv
      %endif 
\
  %endif
  \
  ##---------------------------------------------------scatter
%if b.name == "scatter":
    <%
      (typename, attribs, array_size) = tm.find_typeinfo(b.var)
      (yes, repcount, xx) = tm.in_a_loop_context_are_we(b)
      #infer_implicit_loop = int(array_size) > 1 and not (yes and repcount > 1 and repcount <= int(array_size))
      infer_implicit_loop = int(array_size) > 1 # and not (repcount > 1 and repcount <= int(array_size))
 
      dstAddr = om.taskmap(b.dst_list[0])
      dst_list = list(map(om.taskmap, b.dst_list))
      items_per_dst = array_size//len(dst_list)
      out_vc = 0
      %>\
      `ifdef DEBUGPRINTS0
      $display("[%d] STATE (enter) ${tm.get_task_name()}:\t ${b.name}_${b.depth}${bl.index(b)}", cticks);
      `else
      noAction;
      `endif 
      %for cnt, dst in enumerate(dst_list):
  repeat(${items_per_dst})
  seq
      noAction;noAction;noAction; //TODO FIX
       action
       outFifo.enq(tuple3(${dst}, tagged T${typename} ${b.var}.sub(${cnt*items_per_dst}+${b.var}_indexcntr), (${out_vc})));
         if (${b.var}_indexcntr < ${items_per_dst})
         ${b.var}_indexcntr <= ${b.var}_indexcntr + 1;//${cnt}
         else
         ${b.var}_indexcntr <= 0;
      endaction 
      endseq // scatter chunk ${cnt}
      ${b.var}_indexcntr <= 0;
     %endfor
     
     `ifdef DEBUGPRINTS1
        $display("[%d] STATE (exit) ${tm.get_task_name()}:\t ${b.name}_${b.depth}${bl.index(b)}", cticks);
      `endif 


%endif 
  ##---------------------------------------------------scatter
%if b.name == "send":
          <%
            (typename, attribs, array_size) = tm.find_typeinfo(b.var)
            (yes, repcount, xx) = tm.in_a_loop_context_are_we(b)
            #infer_implicit_loop = int(array_size) > 1 and not (yes and repcount > 1 and repcount <= int(array_size))
            infer_implicit_loop = int(array_size) > 1 # and not (repcount > 1 and repcount <= int(array_size))
          %>\
      %if infer_implicit_loop:
        repeat(${array_size})
        seq
      %endif 
          `ifdef DEBUGPRINTS0
          $display("[%d] STATE (enter) ${tm.get_task_name()}:\t ${b.name}_${b.depth}${bl.index(b)}", cticks);
          `else
          noAction;
          `endif 
          <%
            dstAddr = om.taskmap(b.dst_list[0])
            use_saved_source_address = False
            if dstAddr == None:
              use_saved_source_address = True
            out_vc  = om.get_vc(tm, b)
          %>\
            action
            %if tm.instance_has_attrib_state(b.var):
                %if array_size == 1:
                    outFifo.enq(tuple3(${dstAddr}, tagged T${typename} ${b.var}, (${out_vc})));
                %else:
                    outFifo.enq(tuple3(${dstAddr}, tagged T${typename} ${b.var}.sub(${b.var}_indexcntr), (${out_vc})));
                    if (${b.var}_indexcntr < ${array_size})
                      ${b.var}_indexcntr <= ${b.var}_indexcntr + 1;
                    else 
                      ${b.var}_indexcntr <= 0;
                %endif                     
  `ifdef INSTRUMENT_PRINTS
  $display("EVENTTRACE %d ${tm.get_task_name()} send-buffer ${tm.mapped_to_node}:${dstAddr} ${om.get_flits_in_type(typename)} vc=${out_vc}", cticks);
  `endif 
             %else:
                 %if use_saved_source_address:
                  `ifdef DEBUGPRINTS2 
                  $display("send address, using last saved: %d", saved_source_address);
                  `endif 
  `ifdef INSTRUMENT_PRINTS
  $display("EVENTTRACE %d ${tm.get_task_name()} send-buffer ${tm.mapped_to_node}:%d ${om.get_flits_in_type(typename)} vc=${out_vc}", cticks, saved_source_address);
  `endif 
                     outFifo.enq(tuple3(saved_source_address, tagged T${typename} ${b.var}.first, (${out_vc})));
                 %else:
                     outFifo.enq(tuple3(${dstAddr}, tagged T${typename} ${b.var}.first, (${out_vc})));
  `ifdef INSTRUMENT_PRINTS
 // $display("EVENTTRACE %d ${tm.get_task_name()} send-buffer ${tm.mapped_to_node}:${dstAddr} ${om.get_flits_in_type(typename)} vc=${out_vc}", cticks);
  `endif 
                 %endif
             %endif 
             %if not tm.is_instance_alive(b.children[0].var, b.getpos()):
               ${b.var}.deq(); 
             %endif
            endaction
             
             // use: ${b.children[0].parentspos} ${tm.is_instance_alive(b.children[0].var, b.getpos())}
            `ifdef DEBUGPRINTS1
            $display("[%d] STATE (exit) ${tm.get_task_name()}:\t ${b.name}_${b.depth}${bl.index(b)}", cticks);
            `endif 
      %if infer_implicit_loop:
          endseq //send loop
      %endif 
          %endif 

      %if b.name == "sendif":
          if (${b.var}.notEmpty)  seq 
          `ifdef DEBUGPRINTS0
          $display("[%d] STATE (enter) ${tm.get_task_name()}:\t ${b.name}_${b.depth}${bl.index(b)}", cticks);
          `endif 
          <%
            (typename, attribs, array_size) = tm.find_typeinfo(b.var)
            dstAddr = om.taskmap(b.dst_list[0])
            out_vc  = om.get_vc(tm, b)
          %>\
          action
  `ifdef INSTRUMENT_PRINTS
  $display("EVENTTRACE %d ${tm.get_task_name()} send-buffer ${tm.mapped_to_node}:${dstAddr} ${om.get_flits_in_type(typename)} vc=${out_vc}", cticks);
  `endif 
             outFifo.enq(tuple3(${dstAddr}, tagged T${typename} ${b.var}.first, (${out_vc})));
             %if not tm.is_instance_alive(b.children[0].var, b.getpos()):
               ${b.var}.deq(); 
             %endif
            endaction
             
             // use: ${b.children[0].parentspos} ${tm.is_instance_alive(b.children[0].var, b.getpos())}
            `ifdef DEBUGPRINTS1
            $display("[%d] STATE (exit) ${tm.get_task_name()}:\t ${b.name}_${b.depth}${bl.index(b)}", cticks);
            `endif 
          endseq
      %endif 


      %if b.name == "kernel":
        %if b.kernel_name in tm.kernels_pelib_info:
      `ifdef DEBUGPRINTS0
        $display("[%d] STATE (enter) ${tm.get_task_name()}:\t kernel_${b.depth}${bl.index(b)}", cticks);
      `endif 
  `ifdef INSTRUMENT_PRINTS
  $display("EVENTTRACE %d ${tm.get_task_name()} kernel-start ${b.kernel_name} ", cticks);
  `endif 
          <% 
          modname = tm.kernels_pelib_info[b.kernel_name][1]
          kobj = 'kern_'+modname
          #(iargs, oargs, stateregs) = tm.get_pe_decl_portname_instancename_tuple(b)
          pedecl = om.get_pe_decl(b.kernel_name)
          %>\

    ${kobj}.start();
    await(${kobj}.done());
  <%doc>
            action
            %for (inst, portname, tname) in iargs:
                ${kobj}.${portname}_in.put(${inst}.first());
              %if not tm.is_instance_alive(inst, b.getpos()):
                  ${inst}.deq(); //${tm.is_instance_alive(inst, b.getpos())}
              %endif
            %endfor
            %for (inst, portname, tname) in stateregs:
                ${kobj}.${portname}_in.put(${inst});
            %endfor 
            endaction
            action
            %for (inst, portname, tname) in oargs:
                %if tm.is_this_kernel_output_optional(inst):
                if (${kobj}.${portname}_out_notEmpty()) begin // if notEmpty
                let x${inst} <- ${kobj}.${portname}_out.get();
              ${inst}.enq(x${inst}); // ${tm.is_instance_alive(inst, b.getpos())}
            end // end if notEmpty
                %else:
                    let x${inst} <- ${kobj}.${portname}_out.get();
              ${inst}.enq(x${inst}); // ${tm.is_instance_alive(inst, b.getpos())}
                %endif
            %endfor
            %if '__vivado_ap_none__' not in pedecl.qualifiers:
            %for (inst, portname, tname) in stateregs:
                let x${inst} <- ${kobj}.${portname}_out.get();
                 ${inst}._write(x${inst});
            %endfor 
            %endif
            endaction 
  </%doc>
  `ifdef INSTRUMENT_PRINTS
  $display("EVENTTRACE %d ${tm.get_task_name()} kernel-end ${b.kernel_name} ", cticks);
  `endif 
      `ifdef DEBUGPRINTS1
        $display("[%d] STATE (exit) ${tm.get_task_name()}:\t kernel_${b.depth}${bl.index(b)}", cticks);
      `endif 
        %endif
    %endif 
\
  %if nested:
      endseq  //${b.name}_${b.depth}${bl.index(b)}
  %else:
    endseq;
  %endif 
%endfor 
</%def>\

<% top_bl = tm.get_immediate_blocks() %>\
## STMT_GEN top level
${fsmstmt_gen_immediate_blocks(bl=top_bl)}

<%def name="compose_stmtfsm_instances(bl)">
  %for b in bl:
        ${b.name}_${b.depth}${bl.index(b)};
  %endfor
</%def>\

Stmt top = seq 
noAction;
%if top_bl:
     while(True) seq //implicit loop
${compose_stmtfsm_instances(bl=top_bl)}
    endseq
%endif 
endseq;

mkAutoFSM(top);
## vim: ft=mako
