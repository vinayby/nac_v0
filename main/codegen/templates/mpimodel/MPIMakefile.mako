## vim: noexpandtab ft=mako
# vim: noexpandtab ft=make
<%
import os
host_tasks = [tname for  _,tname,_ in _am.get_tasks_marked_for_exposing_flit_SR_ports()]
num_processes = 1+len(_am.tmodels)
hls_source_paths = [os.path.join(_am.vhlswrappergen_dir, fn+'.cpp') for fn in hls_func_list]
hls_source_paths = [os.path.relpath(f, _am.out_swmodeldir) for f in hls_source_paths]
%>

vivado_hls_path:=$(subst Vivado,Vivado_HLS,$(XILINX_VIVADO))

all: empi 

#m4pass: ${' '.join('natask_{}.postm4.cpp'.format(tname) for tname in host_tasks)}

%for tname in host_tasks:
natask_${tname}.postm4.cpp: ../libna/na_hostmacros.m4 natask_${tname}.cpp 
	m4 -P ../libna/na_hostmacros.m4 natask_${tname}.cpp > natask_${tname}.postm4.cpp 
%endfor 

empi: ${' '.join('natask_{}.postm4.cpp'.format(tname) for tname in host_tasks)}  mpimodel_main.cpp ${" ".join(hls_source_paths)} rewrapped_hwkernels.cpp
	mpic++ -Wfatal-errors -o empi -I <%text>${vivado_hls_path}</%text>/include/ -I../libs/vhls_include -I ../libna -I ${os.path.relpath(_am.vhlswrappergen_dir, _am.out_swmodeldir)} mpimodel_main.cpp ${' '.join('natask_{}.postm4.cpp'.format(tname) for tname in host_tasks)}


run:
	mpirun -np ${num_processes} --output-filename 1out ./empi
	
clean:
	rm -f ./empi 1out.*
