//NO_AUTOREPLACE
#include "vhls_natypes.h"





void plus1(X v, X *vo) {
    /* avoid pure combinational modules */
    #pragma HLS latency min=1
    #pragma HLS INTERFACE ap_none port=v
    #pragma HLS data_pack variable=v

    #pragma HLS INTERFACE ap_none port=vo
    #pragma HLS data_pack variable=vo
    
  vo->v = v.v + 100;
}

