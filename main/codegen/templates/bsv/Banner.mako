<%!
  def chunks(l, n):
     return [l[i:i+n] for i in range(0, len(l), n)]
%>\
<%! from time import strftime as time %>\
##// Generated at ${time('%Y/%m/%d %H:')} 
//
// Input Description: ${_am.nafile_path}
##// NOC: ${_am.psn.dir}

##// CONNECT parameters: 
##%for x in chunks(list(_am.psn.params.items()), 4):
##// ${x}
##%endfor 
//
// LastCommit# ${_am.get_project_sha()[:24]}
//
// -vby
