/*********** vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4 
   mpic++  -I /opt/Xilinx/Vivado_HLS/2016.4/include/  -I 1_VHLSWRAPPERS/  1_VHLSWRAPPERS/mpimodel_main.cpp -Wfatal-errors -Wp,-fopenmp  -Wl,-lgomp
   mpirun -np 6 stdbuf -oL -eL ./a.out | tee r.log
   mpirun -np 6  --output-filename out ./a.out

*/
#include "mpimodel.h"
<%
import pdb
%>
%for d in _am.hwkdecls:
#define INCLUDE_${d.name}
%endfor 
#include "combined.cpp"
#include "rewrapped_hwkernels.cpp"
// task array instances
%for tiu in _am.tinstances_unexpanded:
%if tiu.num_task_instances: ## TODO
  <%
    import pdb
    #pdb.set_trace()
    tasknamelist = ['{}_{}'.format(tiu.taskname, e) for e in range(tiu.num_task_instances)]
    address_list = list(map(_am.taskmap, tasknamelist))
    import math
    indexwidth = int(math.ceil(math.log(len(address_list), 2)))
  %>
  static unsigned grp_${tiu.taskname}(unsigned index) {
  switch(index) {
  %for i, a in enumerate(address_list):
    case ${i} : return ${a};
  %endfor 
  };
  return -1;
  }
%endif
%endfor 

//#define TYPES_PRINT_AS_HEX // need to use -std=c++11
MPI_Group world_group;
%for tgname in _am.taskgroups:
MPI_Group nagroup_${tgname};
MPI_Comm  nagroup_${tgname}_COMM;
%endfor

%for k, v in _am.type_table.items():
MPI_Datatype mpitype_${k};
%endfor

<%
rank_to_taskid_l   = [(k+1, _am.taskmap(_tm.taskname)) for k, _tm in enumerate(_am.tmodels)]
rank_to_taskname_d = {k+1:_tm.taskname for k, _tm in enumerate(_am.tmodels)}
taskid_to_rank_d = {tid:rank for rank, tid in rank_to_taskid_l}
rank_to_taskid_l_csv = ', '.join(map(lambda x: str(x[1]), rank_to_taskid_l))
%>
%for k, _tm in enumerate(_am.tmodels):
  %if not _tm.is_marked_EXPOSE_AS_SR_PORT:
void natask_${_tm.taskname}(unsigned na_task_id, const char *taskname) {
    NATASK_BEGIN
    <%include file='mpi_task_body.mako.cpp' args="_am=_am,_tm=_tm,type_table=_am.type_table"/>
##  %if _tm.is_marked_EXPOSE_AS_SR_PORT:
##  //while(1) { // implicit loop
##  #include "natask_${_tm.taskname}.postm4.cpp"
##  //}
##  %endif 
    NATASK_END
};
 %endif
%endfor 

void tbmain() { /* the main TB */
    MPI_Finalize();
    return; 
}

int main(int argc, char** argv) {
    int rank;
    int numtasks;
    MPI_Status status_;
    MPI_Init(&argc, &argv);
    // custom types begin
    //
     %for k, v in _am.type_table.items():
    <%
    ll = _am.get_struct_member_start_pos_for_MPItypes(k)
    count = len(v.member_info_tuples)
    #types = ["Bit_"+str(vv) for kk, vv, az in v.member_info_tuples]
    types = []
    for (kk, vv, az, ty) in v.member_n_z_az_ty:
        if ty in _am.basic_type_list:
            types.append(_am.to_mpi_typename(ty))
        else:
            types.append(_am.to_mpi_typename(ty, vv))

    blocklen = [str(az) for kk, vv, az, ty in v.member_n_z_az_ty]
    disp = [str(spos//8) for spos in ll]
    
    %>

    {
    MPI_Datatype type[${count}] = {${', '.join(types)}};
    int blocklen[${count}] = {${', '.join(blocklen)}};
    MPI_Aint disp[${count}] = {${', '.join(disp)}};
    MPI_Type_create_struct(${count}, blocklen, disp, type, &mpitype_${k});
    MPI_Type_commit(&mpitype_${k});
    }
%endfor 
    //////////// custom types end
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
    MPI_Comm_group(MPI_COMM_WORLD, &world_group);

    %for tag, (tg, tgo) in enumerate(_am.taskgroups.items()):
        <%
            tgtidlist = list(map(_am.taskmap, tgo.tasknamelist))
            tgranklist = [str(taskid_to_rank_d[t]) for t in tgtidlist]
        %>
        int nagroup_${tg}_ranks[] = {${', '.join(tgranklist)}};
        MPI_Group_incl(world_group, ${len(tgranklist)}, nagroup_${tg}_ranks, &nagroup_${tg});
        MPI_Comm_create_group(MPI_COMM_WORLD, nagroup_${tg}, ${tag}, &nagroup_${tg}_COMM);  
    %endfor
    if(numtasks < NA_NUMTASKS) {    
        printf("\nInsufficient number of processes. Use: \nmpirun -np %d ./<a.out>\n", NA_NUMTASKS);
        MPI_Finalize();
        exit(1);
    }   
%for k, _tm in enumerate(_am.tmodels):
    if (${k+1} == rank) 
    {
        natask_${_tm.taskname}(${_am.taskmap(_tm.taskname)}, "${_tm.taskname}");
    }
%endfor 
    if (0 == rank) {
        tbmain();
    }
    
    return 0;
}

// vim: ft=cpp
