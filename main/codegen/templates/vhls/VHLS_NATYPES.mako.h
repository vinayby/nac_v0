#ifndef VHLS_TYPES_H
#define VHLS_TYPES_H
#include <ap_int.h>
#include <stdint.h>
#include "mydefines.h"
#include <iomanip>
#define HEX_STREAM_MANIP32 std::hex << std::setw(8) << std::setfill('0')
#define HEX_STREAM_MANIP64 std::hex << std::setw(16) << std::setfill('0')

#define PRAGMA_SUB(x) _Pragma (#x)
#define PRAGMA_HLS(x) PRAGMA_SUB(x)
  <%
  params = _am.psn.params
  type_table = _am.type_table
  max_msg_object_size = _am.get_max_parcel_size()
  %>
%for k, v in type_table.items():
  struct ${k} {
  %for (kk, vv, az), basictype in zip(v.member_info_tuples, v.basictypes):
    %if az == 1:
      %if basictype:
      ${basictype} ${kk};
      %else:
      ap_uint<${vv}> ${kk};
      %endif 
    %else:
      %if basictype:
      ${basictype} ${kk}[${az}];
      %else:
      ap_uint<${vv}> ${kk}[${az}];
      %endif 
    %endif 
  %endfor
    static unsigned size() { return ${_am.get_type_size_in_bits(k)};};
#if 0
    volatile ${k}& operator = (const ${k}& a) volatile {
    %for (kk, vv, az), basictype in zip(v.member_info_tuples, v.basictypes):
       %if az == 1:
           this->${kk} = a.${kk};
       %else:
           for(unsigned i=0; i<${az}; i++) { this->${kk}[i] = a.${kk}[i]; }
       %endif
    %endfor
      return *this;
    }
#endif
  };
  typedef struct ${k} ${k};
%endfor
// convenience ostreams (FShow like)
%for k, v in _am.type_table.items():
inline std::ostream& operator<<( std::ostream& os, const ${k}& f) {
    os <<"${k} { ";
    %for (kk, vv, az), basictype in zip(v.member_info_tuples, v.basictypes):
       <%
##            if not basictype:
##                 print("nonbasic types not supported now for os<<")
##                 pdb.set_trace()
       %>
       %if az == 1:
            os << "${kk}: "<< HEX_STREAM_MANIP32 <<f.${kk}<<" ";
       %else:
           os << "${kk}: <V ";
           for(unsigned i=0; i<${az}; i++) {
               //os << i <<": "<< f.${kk}[i] <<" "; // with index
#if defined(TYPES_PRINT_AS_HEX)
            %if basictype in ['float', 'double']:
               os << std::hexfloat << f.${kk}[i] <<", "; // hex
            %else:
               os << std::hex << f.${kk}[i] <<", "; // hex
            %endif
#else
            %if basictype in ['float', 'double']:
               os << std::fixed << f.${kk}[i] <<" "; // fixed
            %else:
               os << +f.${kk}[i] <<", "; // default
            %endif
#endif
           } // for 
           os << ">, ";
       %endif

    %endfor 
    os << "}";
    return os;
}
%endfor

#endif

