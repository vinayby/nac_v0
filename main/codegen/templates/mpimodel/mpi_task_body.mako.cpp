<%page args="_am,_tm,type_table"/>\
<%
  import pdb,math
  _task_name = 'Task_'+ _tm.taskdefname
  ll = _tm.get_taskinstance_type_param_value_list()
  taskid_parameters = ['unsigned {} = {};'.format(p, _am.taskmap(v)) for ptype, p, v in ll if ptype == 'task' ]
%>
##################################################################################################
${'\n'.join(taskid_parameters)}

// Storage 
%for k, v in _tm.symbol_table.items():
  <%
    dict_var_npoa, sendrecv_class_nodes = _tm.get_dict_instance_symbol_to_number_of_points_of_access()
  %>
  
  %if v.storage_class in ['__bram__', '__reg__']:  
    %if v.arraysize == 1:
      ${v.typename} ${k};
    %else:
      ${v.typename} ${k}[${v.arraysize}];
    %endif
  
  %elif v.storage_class in ['__fifo__']:
    //std::queue<${v.typename}> ${k}; 
    %if v.arraysize == 1:
      MyFIFO<${v.typename}, 1>  ${k};
    %else:
      MyFIFO<${v.typename}, ${v.arraysize}>  ${k};
    %endif

  %else:
    NOTSUPPORTED_YET 
  
  %endif 

%endfor
########### SPECIAL FLAGS
## PingPong send and recv staements 
%for b in _tm.get_send_recv_statements_tagged_pingpong():
  bool pingpong_${b.lineno} = true; // <- mkReg(1);
%endfor 
##################################################################################################
##################################################################################################

<%def name="ENTRY_LOG(b=None,forcedebug=False)">
  %if forcedebug or _am.trace_state_entry_exit():
    %if b.name in ['kernel_call']:
      printf("STATE (enter) %s:\t ${b.stmtuniq_tag} (${b.kernel_name})\n", taskname);
    %else:
      printf("STATE (enter) %s:\t ${b.stmtuniq_tag}\n", taskname);
    %endif
%else:
  %if b.name in ['send', 'scatter', 'barrier', 'recv', 'gather']:
  %endif 
%endif  
</%def>

<%def name="EXIT_LOG(b=None, forcedebug=False)">
%if forcedebug or _am.trace_state_entry_exit():
    %if b.name in ['kernel_call' ]:
      printf("STATE (exit) %s:\t ${b.stmtuniq_tag} (${b.kernel_name})\n", taskname);
    %else:
      printf("STATE (exit) %s:\t ${b.stmtuniq_tag}\n", taskname);
    %endif
%endif  
</%def>\

##################################################################################################
<%def name="body_mcopy(b)">
  <% 
   sefrom = _tm.symbol_table[b.varfrom]
   seto = _tm.symbol_table[b.varto]
   infer_loop = sefrom.arraysize > 1
   offset, length = b.offset,b.length
   if length == 'all':
     length = sefrom.arraysize-offset
  %>
  unsigned offset=${offset}, length=${length};
  %if length == 1: 
    {
    %if sefrom.storage_class == '__fifo__':
      ${b.varto} = ${b.varfrom}.first(); ${b.varfrom}.deq();
    %else:
       ${b.varto} = ${b.varfrom};
    %endif  
    }
%else:
  for(unsigned i=offset; i<offset+length; i++){
    %if sefrom.storage_class == '__fifo__':
      ${b.varto}[i] = ${b.varfrom}[i].first(); ${b.varfrom}[i].deq();
    %else:
      ${b.varto}[i] = ${b.varfrom}[i];
    %endif 
    }
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
  %>
  %if infer_loop:
    
  unsigned offset=${offset}, length=${length};
  for(unsigned i=offset; i<offset+length; i++) {
  std::cout << "${b.stmtuniq_tag} instance=${b.var}\t" << ${b.var}[i] << taskname << std::endl;
  }

  %else:
    std::cout << "${b.stmtuniq_tag} instance=${b.var}\t" << ${b.var} << taskname << std::endl;

  %endif

</%def>
##################################################################################################
<%def name="body_delay(b)">
  usleep(100*${b.delayccs});
</%def>
##################################################################################################
<%def name="body_halt(b)">
  ${ENTRY_LOG(b=b)}
  printf("${b.stmtuniq_tag}\t", taskname);
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
   address0 = _am.taskmap(b.address_list[0])
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
   is_non_standard_type = _am.type_table[se.typename].has_non_standard_types 
  %>
%if multiple_sources:
  int source_address = MPI_ANY_SOURCE;
%else:
  int source_address = taskid_to_rank[${address0}];  
%endif 

  ${ENTRY_LOG(b=b)}
%if not infer_loop:
      %if is_non_standard_type:
        ${se.typename}_mpi ${b.var}_;
        MPI_Recv(&${b.var}_, 1, mpitype_${se.typename}, source_address, ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
        
        %if se.storage_class == '__fifo__':
          ${b.var}.enq(myconvert(${b.var}_));
        %else:
          ${b.var} = myconvert(${b.var}_);
        %endif 
      
      %else: 
        ${se.typename} torecv_;
        MPI_Recv(&torecv_, 1, mpitype_${se.typename}, source_address, ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
        
        %if se.storage_class == '__fifo__':
          ${b.var}.enq(torecv_);
        %else:
          ${b.var} = torecv_;
        %endif 

      %endif
    
      #if defined(MPI_DEBUG_1)
      int items_received;
      MPI_Get_count(&mpistat, mpitype_${se.typename}, &items_received); 
      std::cout << "MPI_Recv status: mpistat.MPI_SOURCE= "<< mpistat.MPI_SOURCE  << " mpistat.MPI_TAG=" << mpistat.MPI_TAG << " items_received="<<items_received<< std::endl;
      #endif 
%else:
    unsigned offset=${offset}, length=${length};
    unsigned effective_offset=${offset};
    
    %if use_half_pingpong:
        if (pingpong_${b.lineno}){
        effective_offset = offset;
        } else {
        effective_offset = length-offset;
        }
    %endif 
    %if _am.args.new_tofrom_network:
      %if is_non_standard_type:
      {
        ${se.typename}_mpi ${b.var}_[length];
        MPI_Recv(&${b.var}_[0], length, mpitype_${se.typename}, source_address, ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
        for(unsigned i=effective_offset; i<effective_offset+length; i++) {
              %if se.storage_class == '__fifo__':
            ${b.var}.enq(myconvert(${b.var}_[i-effective_offset]));
              %else:
            ${b.var}[i] = myconvert(${b.var}_[i-effective_offset]);
              %endif 
        }
      }
      %else:
        {
          %if se.storage_class == '__fifo__':
          ${se.typename} torecv_[length];
          MPI_Recv(&torecv_[0], length, mpitype_${se.typename}, source_address, ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
          for(unsigned i=0; i<length; i++) {
            ${b.var}.enq(torecv_[i]);
          }
          %else:
        MPI_Recv(&${b.var}[effective_offset], length, mpitype_${se.typename}, source_address, ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
          %endif
        }
      %endif 
    %else: ## usual 1 item at a time mode
    for(unsigned i=effective_offset; i<effective_offset+length; i++) {
        %if is_non_standard_type:
            ${se.typename}_mpi ${b.var}_;
            MPI_Recv(&${b.var}_, 1, mpitype_${se.typename}, source_address, ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
          
            %if se.storage_class == '__fifo__':
          ${b.var}.enq(myconvert(${b.var}_));
            %else:
          ${b.var}[i] = myconvert(${b.var}_);
            %endif 
      
      %else:
          ${se.typename} torecv_;
          MPI_Recv(&torecv_, 1, mpitype_${se.typename}, source_address, ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
        
          %if se.storage_class == '__fifo__':
            ${b.var}.enq(torecv_);
          %else:
            ${b.var}[i] = torecv_;
          %endif 
        
      %endif
      }
      %endif ## 1 item at a time or bulk
          
      #if defined(MPI_DEBUG_1)
      int items_received;
      MPI_Get_count(&mpistat, mpitype_${se.typename}, &items_received); 
      std::cout << "MPI_Recv status: mpistat.MPI_SOURCE= "<< mpistat.MPI_SOURCE  << " mpistat.MPI_TAG=" << mpistat.MPI_TAG << " items_received="<<items_received<< std::endl;
      #endif 

%endif
  %if use_half_pingpong:
    pingpong_${b.lineno} = !pingpong_${b.lineno};
  %endif 
  ${EXIT_LOG(b=b)}

</%def>
##################################################################################################
##################################################################################################
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
    is_non_standard_type = _am.type_table[se.typename].has_non_standard_types 
  %>
  unsigned effective_offset = 0;
  unsigned length = ${items_per_address};
  %for chunk_index, address in enumerate(address_list):
    effective_offset = ${chunk_index}*length + ${offset};
        for(unsigned i=effective_offset; i<effective_offset+length; i++) {
        %if is_non_standard_type:
              ${se.typename}_mpi ${b.var}_;
              MPI_Recv(&${b.var}_, 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
              ${b.var}[i] = myconvert(${b.var}_);
        %else:
              MPI_Recv(&${b.var}[i], 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD, &mpistat);
        %endif 
        }
  %endfor 

  <%doc>
  unsigned effective_offset = 0;
  unsigned length = ${items_per_address};
  %for chunk_index, address in enumerate(address_list):
    effective_offset = ${chunk_index}*length;
        for(unsigned i=effective_offset; i<effective_offset+length; i++) {
        %if is_non_standard_type:
              ${se.typename}_mpi ${b.var}_ = myconvert(${b.var}[i]);
              MPI_Send(&${b.var}_, 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
        %else:
              MPI_Send(&${b.var}[i], 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
        %endif 
        }
  %endfor 
  </%doc> 
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
%>
 ${ENTRY_LOG(b, True)}
 MPI_Barrier(nagroup_${b.groupname}_COMM);
 <%doc> 
%if _am.args.fnoc_supports_multicast:
    send_synctoken_auto_multicast(fromInteger(${mcm}), 1);
    par 
  %for address in address_list:
      seq     action let dontcarer <- recv_synctoken(${address}); endaction    }
  %endfor
    endpar 
%else:
  
  %for address in address_list:
     send_synctoken(${address}, 1, 0);
  %endfor
  
  par 
  %for address in address_list:
      seq action let dontcarer <- recv_synctoken(${address}); endaction    }
  %endfor 
  endpar 
%endif   
</%doc>
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

  %elif se.storage_class == '__ram__':
    ${b.var}.readReq(${b.var}_index_${b.lineno} + ${offset});
    action 
    let rx <- ${b.var}.readResp(); 
    ${b.var}_reg <= rx;
    endaction 
 
  %elif se.storage_class == '__mbus__':
    ${b.var}.readReq(${b.var}_index_${b.lineno} + ${offset});
    let rx <- ${b.var}.readResp(); 
    ${b.var}_reg <= rx;
    endaction 
 
  %endif
</%def>
<%def name="collect_and_send_out_action(se, b, address, out_vc, last_destination_address, length)">
  action
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
        else 
          ${b.var}_index_${b.lineno} <= 0;
        %endif
    %elif se.storage_class == '__ram__':
        let sendobj_val = ${b.var}_reg;
        %if last_destination_address:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else 
          ${b.var}_index_${b.lineno} <= 0;
        %endif
    %elif se.storage_class == '__mbus__':
        //let sendobj_val <- ${b.var}.mem.portA.response.get;
        //let sendobj_val <- ${b.var}.readRsp();
        let sendobj_val = ${b.var}_reg;
        %if last_destination_address:
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
        %if last_destination_address:
        if (${b.var}_index_${b.lineno} < ${length-1})
          ${b.var}_index_${b.lineno} <= ${b.var}_index_${b.lineno} + 1;
        else 
          ${b.var}_index_${b.lineno} <= 0;
       %endif
      %endif 
    %endif ## se.storage_class
    outFifo.enq(tuple4(${address}, tagged T${se.typename} sendobj_val, ${out_vc}, 0));
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
    }
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
    }
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
    }
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
   address = _am.taskmap(b.address_list[0])
   address_list = list(map(_am.taskmap, b.address_list))
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
   is_non_standard_type = _am.type_table[se.typename].has_non_standard_types 
  %>\
unsigned offset=${offset}, length=${length};
unsigned effective_offset=${offset};
%if use_half_pingpong:
    if (pingpong_${b.lineno}){
    effective_offset = offset;
    } else {
    effective_offset = length-offset;
    }
%endif 

  ${ENTRY_LOG(b=b)}
%for address_idx, address in enumerate(address_list):

  %if not infer_loop:
    %if is_non_standard_type:
      %if se.storage_class == '__fifo__':
        ${se.typename}_mpi ${b.var}_ = myconvert(${b.var}.first()); ${b.var}.deq();
      %else:
        ${se.typename}_mpi ${b.var}_ = myconvert(${b.var});
      %endif 

        MPI_Send(&${b.var}_, 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
    %else:
      %if se.storage_class == '__fifo__':
        ${se.typename} tosend_ = ${b.var}.first(); ${b.var}.deq();
      %else:
        ${se.typename} tosend_ = ${b.var};
      %endif 
     
      MPI_Send(&tosend_, 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
    %endif 
      
  %else:
    %if _am.args.new_tofrom_network:
      %if is_non_standard_type:
      {
        ${se.typename}_mpi ${b.var}_[length];
        for(unsigned i=effective_offset; i<effective_offset+length; i++) {
              %if se.storage_class == '__fifo__':
                ${b.var}_[i-effective_offset]=myconvert(${b.var}.first()); ${b.var}.deq();
              %else:
                ${b.var}_[i-effective_offset] = myconvert(${b.var}[i]);
              %endif 
        }
        MPI_Send(&${b.var}_[0], length, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
      }
      %else:
        {
          %if se.storage_class == '__fifo__':
            ${se.typename} tosend_[length];
          for(unsigned i=0; i<length; i++) {
            tosend_[i] = ${b.var}.first(); ${b.var}.deq();
          }
          MPI_Send(&tosend_[0], length, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
          %else:
          MPI_Send(&${b.var}[effective_offset], length, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
          %endif
        }
      %endif 
    %else:
        for(unsigned i=effective_offset; i<effective_offset+length; i++) {
        %if is_non_standard_type:
      %if se.storage_class == '__fifo__':
        ${se.typename}_mpi ${b.var}_ = myconvert(${b.var}.first()); ${b.var}.deq();
      %else:
        ${se.typename}_mpi ${b.var}_ = myconvert(${b.var}[i]);
      %endif 

          MPI_Send(&${b.var}_, 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
        %else:
      %if se.storage_class == '__fifo__':
        ${se.typename} tosend_ = ${b.var}.first(); ${b.var}.deq();
      %else:
        ${se.typename} tosend_ = ${b.var}[i];
      %endif 

          MPI_Send(&tosend_, 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
        %endif 
        }
     %endif ## 1 item at time or bulk
  %endif

%endfor 
  %if use_half_pingpong:
    pingpong_${b.lineno} = !pingpong_${b.lineno};
  %endif 
  ${EXIT_LOG(b=b)}
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
    is_non_standard_type = _am.type_table[se.typename].has_non_standard_types 
  %>
  unsigned effective_offset = 0;
  unsigned length = ${items_per_address};
  %for chunk_index, address in enumerate(address_list):
    effective_offset = ${chunk_index}*length;
        for(unsigned i=effective_offset; i<effective_offset+length; i++) {
        %if is_non_standard_type:
              ${se.typename}_mpi ${b.var}_ = myconvert(${b.var}[i]);
              MPI_Send(&${b.var}_, 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
        %else:
              MPI_Send(&${b.var}[i], 1, mpitype_${se.typename}, taskid_to_rank[${address}], ${_am.typename2tag(se.typename)}, MPI_COMM_WORLD);
        %endif 
        }
  %endfor 

  ${EXIT_LOG(b=b)}
</%def>
##################################################################################################
<%def name="body_kernel_call(b)">
  ${ENTRY_LOG(b,True)}
  ${b.kernel_name}(${_tm.get_csv_arguments_for_kernel_for_cpp_model(b)});
  ${EXIT_LOG(b,True)}
</%def>
##################################################################################################
##################################################################################################
<%def name="fsmstmt_gen_immediate_blocks(bl, nested=False)">
%for b in bl:
  %if nested:
      { //  ${b.stmtuniq_tag}; nesting                                
  %else:
      { //  ${b.stmtuniq_tag}; not nesting  
  %endif 
  ############################# loop_block // repeat variety
  %if b.name == 'loop_block':
    %if b.has_loopindex:  ## loop index specs
    <%
      li = b.children[0]
    %>
    for(unsigned loopidx_${li.index_var}= ${li.start_index};  loopidx_${li.index_var} < ${li.max_index}; loopidx_${li.index_var} = loopidx_${li.index_var}+${li.index_incr})  {
        ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
      } 

    %elif b.repeatcount == -1:
      while(true) {
        ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
      } 
    %else:
      for(unsigned i_${b.stmtuniq_tag}=0; i_${b.stmtuniq_tag}<${b.repeatcount}; i_${b.stmtuniq_tag}++)  
      {
        ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
      } // repeat(${b.repeatcount})
    %endif 
  %endif
  ############################# parallel_block
  %if b.name == "parallel_block":
    // par // parallel-------------------------------------------------------------------------------------
     ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
    // endpar // endparallel-------------------------------------------------------------------------------
  %endif 
  ############################# group_block
  %if b.name == "group_block":
    { // group
     ${fsmstmt_gen_immediate_blocks(bl=_tm.get_immediate_blocks(b), nested=True)}
    } // endgroup
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
    }  //${b.stmtuniq_tag} 
  %else: 
    }; //${b.stmtuniq_tag} 
  %endif 
%endfor 
</%def>
##################################################################################################
##################################################################################################
<%def name="compose_stmtfsm_instances(bl)">
  %for b in bl:
   // ${b.stmtuniq_tag};
  %endfor 
</%def>
##################################################################################################
##################################################################################################
<% 
top_bl = _tm.get_immediate_blocks() 
%>\
%if top_bl:
  while(1) { //implicit loop
${fsmstmt_gen_immediate_blocks(bl=top_bl)}
  }
%endif 

##################################################################################################
##################################################################################################
## vim: ft=mako
