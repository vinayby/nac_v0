/*********** vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4 

*/
#include<math.h>
#include<mpi.h>
#include<cstdio>
#include<cstdlib>
#include<time.h>
#include<unistd.h>
#include<vector>
#include<csignal>
#include <sys/time.h>

#include "myfifo.h"
#include "vhls_natypes.h"
<%
import pdb
%>

//#define TYPES_PRINT_AS_HEX // need to use -std=c++11
extern MPI_Group world_group;
%for tgname in _am.taskgroups:
extern MPI_Group nagroup_${tgname};
extern MPI_Comm  nagroup_${tgname}_COMM;
%endfor

#define NA_NUMTASKS ${len(_am.tmodels)+1} // tasks + the main spawing thread (rank 0) in MPI
%for k, v in _am.type_table.items():
extern MPI_Datatype mpitype_${k};
%endfor

<%
rank_to_taskid_l   = [(k+1, _am.taskmap(_tm.taskname)) for k, _tm in enumerate(_am.tmodels)]
rank_to_taskname_d = {k+1:_tm.taskname for k, _tm in enumerate(_am.tmodels)}
taskid_to_rank_d = {tid:rank for rank, tid in rank_to_taskid_l}
rank_to_taskid_l_csv = ', '.join(map(lambda x: str(x[1]), rank_to_taskid_l))
%>
// type conversions where necessary

%for k, v in _am.type_table.items():
    %if not v.has_non_standard_types:
##<% continue %>
    %endif 
typedef struct {
    %for (kk, vv, az, ty) in v.member_n_z_az_ty:
       %if az == 1:
            %if ty in _am.basic_type_list: 
                ${ty} ${kk};
            %else:
                unsigned long ${kk};
            %endif 
       %else:
            %if ty in _am.basic_type_list: 
                ${ty} ${kk}[${az}];
            %else:
                unsigned long ${kk}[${az}];
            %endif 
       %endif
    %endfor 
} ${k}_mpi;
inline ${k}_mpi myconvert(const ${k}& f) {
    ${k}_mpi to;
    %for kk, vv, az,ty in v.member_n_z_az_ty:
       %if az == 1:
        %if ty in _am.basic_type_list: 
            to.${kk} = f.${kk};
        %else:
            to.${kk} = f.${kk}.range(${vv-1},0);
        %endif 
       %else:
           for(unsigned i=0; i<${az}; i++) {
        %if ty in _am.basic_type_list: 
            to.${kk}[i] = f.${kk}[i];
        %else:
            to.${kk}[i] = f.${kk}[i].range(${vv-1},0);
        %endif 
           } // for 
       %endif
    %endfor 
    return to;
}
inline ${k} myconvert(const ${k}_mpi& f) {
    ${k} to;
    %for kk, vv, az,ty in v.member_n_z_az_ty:
       %if az == 1:
        %if ty in _am.basic_type_list: 
            to.${kk} = f.${kk};
        %else:
            to.${kk}(${vv-1},0) = f.${kk};
        %endif 
       %else:
           for(unsigned i=0; i<${az}; i++) {
        %if ty in _am.basic_type_list: 
            to.${kk}[i] = f.${kk}[i];
        %else:
            to.${kk}[i](${vv-1},0) = f.${kk}[i];
        %endif 
           } // for 
       %endif
    %endfor 
    return to;
}
%endfor

%for k, _tm in enumerate(_am.tmodels):
void natask_${_tm.taskname}(unsigned na_task_id, const char *taskname);
%endfor 

#define NATASK_BEGIN ${'\\'}
    int rank; ${'\\'}
    int32_t rank_to_taskid[NA_NUMTASKS] = {-1, ${rank_to_taskid_l_csv}}; ${'\\'}
    static int32_t taskid_to_rank[${_am.number_user_send_ports}] = {-1}; ${'\\'}
    static int32_t taskname_to_taskid[${_am.number_user_send_ports}] = {-1}; ${'\\'}
    %for r, tid in rank_to_taskid_l: 
    taskid_to_rank[${tid}] = ${r}; static int32_t tid_${rank_to_taskname_d[r]} = ${_am.taskmap(rank_to_taskname_d[r])}; ${'\\'}
    %endfor 
    NATaskInfo task_info; task_info.node_id = na_task_id; ${'\\'}
    %for ty,tag in _am.typetags.items():
      static const unsigned natypetag_${ty} = ${tag}; ${'\\'}
    %endfor
    double wtime = MPI_Wtime(); ${'\\'}
    static MPI_Status mpistat; ${'\\'}
    MPI_Comm_rank(MPI_COMM_WORLD, &rank); ${'\\'}
    printf("start:%s na_task_id=%d rank=%d\n", taskname, rank_to_taskid[rank], rank); 


#define NATASK_END ${'\\'}
    wtime = MPI_Wtime() - wtime; ${'\\'}
    printf("[%g] end:%s na_task_id=%d rank=%d\n", wtime, taskname, na_task_id, rank); ${'\\'}
    MPI_Abort(MPI_COMM_WORLD, 0); ${'\\'}
    MPI_Finalize(); ${'\\'}
    return;

