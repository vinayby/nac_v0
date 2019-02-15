<%!
  def chunks(l, n):
     return [l[i:i+n] for i in range(0, len(l), n)]
%>\
<%! from time import strftime as time %>\
// Generated at ${time('%Y/%m/%d %H:%M')} 
//
// Input Description: ${om.nafile_path}
// NOC: ${om.noctouse}

// CONNECT parameters: 
%for x in chunks(list(om.params.items()), 4):
// ${x}
%endfor 
//
// LastCommit# ${om.get_project_sha()[:24]}
//
// -vby
