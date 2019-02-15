//NO_AUTOREPLACE
#include "vhls_natypes.h"





void plus1f(XF v, XF *vo) {
    /* avoid pure combinational modules */
    #pragma HLS latency min=1
    #pragma HLS INTERFACE ap_none port=v
    #pragma HLS data_pack variable=v

    #pragma HLS INTERFACE ap_none port=vo
    #pragma HLS data_pack variable=vo

    vo->v = v.v + 1.1;
    vo->a = v.a + 1;
    for(unsigned i=0;i<4;i++)
      vo->b[i] = v.b[i]+1;
    for(unsigned i=0;i<3;i++)
      vo->c[i] = v.c[i]+1.1;
    for(unsigned i=0;i<2;i++)
      vo->e[i] = v.e[i]+1.1;
    vo->d = v.d+1;
    ap_ufixed<32,16> onep1 = 1.1;
    vo->f = v.f+onep1;
}

