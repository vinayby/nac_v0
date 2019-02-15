##=================================================================================================                                                                         
## PREPARATION 
##=================================================================================================                                                                         
<%page args="_tm,_am"/>
 <% 
 _task_name = 'Task_'+ _tm.taskname
 _taskdef_name = 'Task_' + _tm.taskdefname
 if not _tm.is_task_instance():
  _taskdef_name = _task_name
 incoming_types = _tm.get_list_of_types_incoming_and_outgoing()[0]
 outgoing_types = _tm.get_list_of_types_incoming_and_outgoing()[1]

 using_sync = True

 p_tnvl = _tm.get_taskinstance_type_param_value_list()
 p_tnvl = [('DestAddr', a[1], _am.taskmap(a[2])) if a[0] == 'task' else a for a in p_tnvl]
 p_tnvl = [('String', a[1], _am.taskmap(a[2])) if a[0] == 'string' else a for a in p_tnvl]
 p_namelist_string = ', '.join([a[1] for a in p_tnvl])
 prefix_ = ','.join(['node_id', 'snode_id', 'task_instance_name'])
 if p_namelist_string:
   p_namelist_string = prefix_ + ',' + p_namelist_string
 else:
   p_namelist_string = prefix_  
%>

<%def name="LIBody()">
      %if _am.enabled_lateral_data_io:
     GetPut#(NARawData) datasr_port_out <- mkGPSizedFIFO(4); 
     GetPut#(NARawData) datasr_port_in  <- mkGPSizedFIFO(4); 
     
  %if p_tnvl or _tm.is_task_instance(): 
  DestAddr node_id = ${_am.taskmap(_tm.taskname)};
  String snode_id = "${_am.taskmap(_tm.taskname)}";
  String task_instance_name = "${_tm.taskname}";
    %for pt, pn, pv in p_tnvl:
      ${pt} ${pn} = ${pv};
    %endfor
  
  %endif ##### p_tnvl or _tm.is_task_instance():

      %if incoming_types:
      Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_taskdef_name}_tuple)) pkt_nw2c  <- replicateM(mkFIFO()); 
      %endif 
\
      %if outgoing_types:
      FIFO#(DispatchUnion${_taskdef_name}_tuple) pkt_c2nw <- mkSizedFIFO(${max(2, len(outgoing_types))});
    %endif   
  Vector#(${len(_am.tmodels)}, FIFO#(Flit)) splf_nw2c <- replicateM(mkFIFO());
  MERGE_FIFOF#(${len(_am.tmodels)}, Flit) splf_c2nw <- mkMergeFIFOF;

           // Loop back test setup for Bulk IO 
           // putRawData >>> (2)::put:: port_in ::get::(1) ------ (2)::put:: port_out ::get::(1)  >>> getRawData 
           // mkConnection(tpl_1(datasr_port_in) /* Get */, tpl_2(datasr_port_out) /* Put */);
           %if _tm.is_task_instance():
           let core <- mk${_taskdef_name}(pkt_c2nw, pkt_nw2c, datasr_port_in, datasr_port_out, ${p_namelist_string});
         %else:
           let core <- mk${_taskdef_name}(pkt_c2nw, pkt_nw2c, datasr_port_in, datasr_port_out);
         %endif 
      let fromCore <- mkToNetwork${_taskdef_name}(pkt_c2nw, splf_c2nw);
      let toCore <- mkFromNetwork${_taskdef_name}(pkt_nw2c, splf_nw2c);
     
      %endif 
</%def>

(* synthesize *)   
module mkNode${_task_name}#(parameter PortId portid)(NodePort);
  let bridge <- mkCnctBridge(portid);
%if _tm.is_marked_off_chip:
## ---------------- outward looking tasks --------------------------------------------BEGIN
%if _am.use_buffering_tofrom_host: ## TODO rename to FLIT_SR_PORTS
     GetPut#(Flit) flitsr_port_out <- mkGPSizedFIFO(${_am.get_buffersize_offchipnode()}); 
     GetPut#(Flit) flitsr_port_in  <- mkGPSizedFIFO(${_am.get_buffersize_offchipnode()}); 
    
     ${LIBody()}    
     
     ############# CONNECTIONS core and bridge 

    for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    %if incoming_types or using_sync:
    mkConnection(bridge.corePort[i].get, toCore.putFlit[i].put);
    %endif 
    %if outgoing_types or using_sync:
    mkConnection(fromCore.getFlit[i].get, bridge.corePort[i].put);
    %endif 
    end
      
  %if _am.enabled_lateral_data_io and not _am.args.either_or_lateral_io:
     mkConnection(tpl_1(flitsr_port_in).get /*Get*/, bridge.corePort[0].put);
     mkConnection(bridge.corePort[0].get, tpl_2(flitsr_port_out).put /* Put */);
    %endif
     
     interface lateralIO = interface LateralIOPort;
     // interface setups 
        interface putFlit = tpl_2(flitsr_port_in);
        interface getFlit = tpl_1(flitsr_port_out);
      %if _am.enabled_lateral_data_io:
        interface putRawData = tpl_2(datasr_port_in); 
        interface getRawData = tpl_1(datasr_port_out); 
      
      %endif 
     endinterface;
  
 %else:
     ${LIBody()}    
    interface lateralIO = interface LateralIOPort;
     // interface setups 
       interface putFlit = interface Put;
         method put = bridge.corePort[0].put;
       endinterface;
       interface getFlit = interface Get; 
         method get = bridge.corePort[0].get;  
       endinterface;
      %if _am.enabled_lateral_data_io:
        interface putRawData = tpl_2(datasr_port_in); 
        interface getRawData = tpl_1(datasr_port_out); 
      %endif 
    endinterface;
## ---------------- outward looking tasks --------------------------------------------END
  %endif 
%else:
  %if p_tnvl or _tm.is_task_instance(): 
  DestAddr node_id = ${_am.taskmap(_tm.taskname)};
  String snode_id = "${_am.taskmap(_tm.taskname)}";
  String task_instance_name = "${_tm.taskname}";
    %for pt, pn, pv in p_tnvl:
      ${pt} ${pn} = ${pv};
    %endfor
  
  %endif ##### p_tnvl or _tm.is_task_instance():
  
  %if incoming_types:
  Vector#(${len(_tm.get_unique_message_sources())}, FIFO#(ReceptionUnion${_taskdef_name}_tuple)) pkt_nw2c  <- replicateM(mkFIFO()); 
  %endif 
\
  %if outgoing_types:
  FIFO#(DispatchUnion${_taskdef_name}_tuple) pkt_c2nw <- mkSizedFIFO(${max(2, len(outgoing_types))});
  %endif   
  Vector#(${len(_am.tmodels)}, FIFO#(Flit)) splf_nw2c <- replicateM(mkFIFO());
  MERGE_FIFOF#(${len(_am.tmodels)}, Flit) splf_c2nw <- mkMergeFIFOF;
  
  ############# CORE
  %if _tm.is_task_instance():
  let core <- mk${_taskdef_name}(\
    %if outgoing_types:
pkt_c2nw, \
    %endif  
    %if incoming_types:
pkt_nw2c, \
    %endif  
splf_nw2c, splf_c2nw, ${p_namelist_string}); 
  %else:
  let core <- mk${_taskdef_name}(\
    %if outgoing_types:
pkt_c2nw, \
    %endif  
    %if incoming_types:
pkt_nw2c, \
    %endif  
splf_nw2c, splf_c2nw); 
  
  %endif

  ############# TO NETWORK  
  %if outgoing_types or using_sync:
    %if _tm.is_task_instance():
  let fromCore <- mkToNetwork${_taskdef_name}(\
      %if outgoing_types:
pkt_c2nw, \
      %endif
      splf_c2nw, node_id, snode_id);
    %else:
  let fromCore <- mkToNetwork${_taskdef_name}(\
      %if outgoing_types:
pkt_c2nw, \
      %endif
splf_c2nw);
    %endif
  %endif 
 
  ############# FROM NETWORK  
  %if incoming_types or using_sync:
    %if _tm.is_task_instance():
  let toCore <- mkFromNetwork${_taskdef_name}(\
      %if incoming_types:
pkt_nw2c, \
      %endif  
      splf_nw2c, node_id, snode_id);
    %else:
  let toCore <- mkFromNetwork${_taskdef_name}(\
      %if incoming_types:
pkt_nw2c, \
      %endif
      splf_nw2c);
    %endif
  %endif 

  ############# CONNECTIONS core and bridge 
  for(Integer i=0; i<valueOf(NUM_VCS); i=i+1) begin
    %if incoming_types or using_sync:
    mkConnection(bridge.corePort[i].get, toCore.putFlit[i].put);
    %endif 
    %if outgoing_types or using_sync:
    mkConnection(fromCore.getFlit[i].get, bridge.corePort[i].put);
    %endif 
  end

%endif

###################################################################################################
## TODO: can make this permanent 
###################################################################################################
%if True:
  //return bridge.nocPort;
  interface nocPort = bridge.nocPort;

%else: 
  %if _am.psn.is_connect_credit():
    method getFlit = bridge.nocPort.getFlit;
    method putCredits = bridge.nocPort.putCredits;
    method setRecvFlit = bridge.nocPort.setRecvFlit;
    method getCredits = bridge.nocPort.getCredits;
    method setRecvPortID = bridge.nocPort.setRecvPortID;

  %elif _am.psn.is_connect_peek() or _am.psn.is_fnoc_peek():
    method getFlit = bridge.nocPort.getFlit;
    method setNonFullVC = bridge.nocPort.setNonFullVC;
    method setRecvFlit = bridge.nocPort.setRecvFlit;
    method getRecvVCMask = bridge.nocPort.getRecvVCMask;
    method setRecvPortID = bridge.nocPort.setRecvPortID;
  %endif

  %if _tm.is_marked_off_chip:
    interface putFlitSoft = bridge.nocPort.putFlitSoft;
    interface getFlitSoft = bridge.nocPort.getFlitSoft;
    // essentially:
    // return bridge.nocPort;
  %endif

%endif 
endmodule

##################################################################################################
##################################################################################################
## vim: ft=mako
