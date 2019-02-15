/* This file has: 
 * - Data type conversions for convenient I/O over SceMI 
 *    - For SceMI this would ultimately be between ap_uint<> to BitT<>, however, as
 *      for this file, it all remains as ap_uint<>
 * - And some other na file specific information
 */

#ifndef SCEMI_NA_UTIL_MAKO_H
#define SCEMI_NA_UTIL_MAKO_H 

template <class T> const T& min_ (const T& a, const T& b) { return (a>b)?b:a; }
// information for use in constructing the header flit
static const unsigned natypetags_bitwidth = ${_am.get_typetags_count_width()}; 
<%
raw_store_of = {'float'   : 'uint32_t', 
                'int'     : 'uint32_t', 
                'int16_t' : 'uint16_t', 
                'int8_t'  : 'uint8_t',
                'double'  : 'uint64_t'
               }
%>
// Type tag values
%for ty,tag in _am.typetags.items():
  static const unsigned natypetag_${ty} = ${tag};
%endfor

// task IDs as in taskmap.json TODO support tarrayname[i];
%for k,_tm in enumerate(_am.tmodels):
  static int32_t tid_${_tm.taskname} = ${_am.taskmap(_tm.taskname)};
%endfor 
// And, instance arrays:
%for tiu in _am.tinstances_unexpanded:
  %if tiu.is_array_declaration:
  static int32_t tid_${tiu.taskname}[] = { 
    ${','.join(str(i) for i in map(_am.taskmap, tiu.generate_instance_names()))}
  };
  %endif
%endfor 

%for k, v in _am.type_table.items():
    %if not v.has_non_standard_types:
##    <% continue %>
    %endif 
    <%
    (nFlits, k_member_items) = _am.get_struct_member_index_ranges_wrt_flitwidth(k)
    k_member_types = [ty for _,_,_,ty in v.member_n_z_az_ty]
    flit_width = _am.psn.params['FLIT_DATA_WIDTH']
    unusual_flitwidth = divmod(int(flit_width), 32) [1] != 0
    %>

typedef struct { 
      ## uint64_t arr_pload[${nFlits+1}]; // +1 for convenience to treat this as an array, not for header
      ap_uint<512> pload;  
      static unsigned size() { return ${_am.get_type_size_in_bits(k)};}; // TODO safety checks
%if false:
    %if  _am.get_type_size_in_bits(k) > 64:
      //SUPPORT_LATER
      ap_uint<${_am.get_type_size_in_bits(k)}> pload;
    %else:
       %if _am.get_type_size_in_bits(k) > 32:
       ap_uint<64> pload;
       %else:
       ap_uint<32> pload;
       %endif 
    %endif 
%endif
} ${k}_scemi;


inline ${k}_scemi myconvert(const ${k}& f) {
    ${k}_scemi to;
##  %if  _am.get_type_size_in_bits(k) > 64:
##    SUPPORT_LATER
##  %else:
       %for i,(epos, spos, vname, az) in enumerate(k_member_items):
    %if k_member_types[i] not in _am.basic_type_list:
         %if az > 1:
           to.pload(${epos},${spos}) =  (${','.join( ['f.{0}[{1}].range(f.{0}[0].length()-1, 0)'.format(vname, i) for i in reversed(range(az))] )});
         %else:
           to.pload(${epos},${spos}) =  f.${vname}.range(f.${vname}.length()-1,0);
         %endif 
    %else:
         %if az > 1:
         {
              %if k_member_types[i] in raw_store_of.keys():
                  {
                 ap_uint< ${(epos-spos+1)//az} > e_[${az}];
                 ${';'.join( ['e_[{1}] = *({2} *)&f.{0}[{1}]'.format(vname, k, raw_store_of[k_member_types[i]]) for k in reversed(range(az))] )};
                 to.pload(${epos},${spos}) =  (${','.join( ['e_[{}]'.format(i) for i in reversed(range(az))] )});
                  }
              %else:
                 ap_uint< ${(epos-spos+1)//az} > e_[${az}];
                 ${';'.join( ['e_[{1}] = f.{0}[{1}]'.format(vname, i) for i in reversed(range(az))] )};
                 to.pload(${epos},${spos}) =  (${','.join( ['e_[{}]'.format(i) for i in reversed(range(az))] )});
              %endif 
         }
         %else:
              %if k_member_types[i] in raw_store_of.keys():
                  {
                  ${k_member_types[i]} e_ = f.${vname};
                  to.pload(${epos},${spos}) =  *(${raw_store_of[k_member_types[i]]} *)&e_;
                  }
              %else:
                  to.pload(${epos},${spos}) =  f.${vname};
              %endif 
         %endif 
    %endif 
       %endfor 
##              
##     for(int i=0; i<${nFlits}; i++) {
##      //DIS to.arr_pload[i] = to.pload.range(min_(${flit_width}*(i+1),${_am.get_type_size_in_bits(k)}) - 1, ${flit_width}*i);
##     }
##                   
  return to;
}
inline ${k} myconvert(const ${k}_scemi& f) {
    ${k} to;
    unsigned mw;
##        for(int i=0; i<${nFlits}; i++) {
## %if unusual_flitwidth:
##         // has data already
##         // f.pload.range(min_(${flit_width}*(i+1),${_am.get_type_size_in_bits(k)}) - 1, ${flit_width}*i) = f.arr_pload[i];
## %else:
##         //DIS f.pload.range(min_(${flit_width}*(i+1),${_am.get_type_size_in_bits(k)}) - 1, ${flit_width}*i) = f.arr_pload[i];
## %endif
##        }
    %for i,(epos, spos, vname, az) in enumerate(k_member_items):
         <%
           last_member_bitpos = 0
           if i>0 and len(k_member_items) > 1:
            last_member_bitpos = k_member_items[i-1][0]+1
         %> 
      %if az > 1: 
       mw = ${epos-spos+1}/${az};
       for(int i=0; i<${az}; i++) {
                        %if k_member_types[i] not in _am.basic_type_list:
                             to.${vname}[i].range(to.${vname}[0].length()-1,0) = f.pload.range(${last_member_bitpos}+ (i+1)*mw-1,${last_member_bitpos}+  mw*i); 
                        %else:
                            %if  k_member_types[i] in raw_store_of.keys():
                              {
                                  ${raw_store_of[k_member_types[i]]} e_ = f.pload.range( ${last_member_bitpos}+ (i+1)*mw-1, ${last_member_bitpos}+ mw*i);
                                  to.${vname}[i] = *(${k_member_types[i]} *)&e_;      
                              }
                            %else:
                                  to.${vname}[i] = f.pload.range( ${last_member_bitpos}+ (i+1)*mw-1, ${last_member_bitpos}+ mw*i); 
                            %endif 
                        %endif 
       }
      %else:
                        %if k_member_types[i] not in _am.basic_type_list:
                            to.${vname}.range(to.${vname}.length()-1,0) = f.pload.range(${epos},${spos});
                        %else:
                            %if  k_member_types[i] in raw_store_of.keys():
                              {
                                  ${raw_store_of[k_member_types[i]]} e_ = f.pload.range(${epos},${spos});
                                  to.${vname} =  *( ${k_member_types[i]} *)&e_;      
                              }
                            %else:
                              to.${vname} = f.pload.range(${epos},${spos});
                            %endif 
                        %endif 
      %endif 
    %endfor 
    return to;
}
%endfor


#endif /* !SCEMI_NA_UTIL_MAKO_H */
