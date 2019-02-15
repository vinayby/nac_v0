/*********** vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4 
 */
#include <iostream>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>                 
#include <stdlib.h>                 
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include <cstdio>
#include "nascemi.h"
#include "vhls_natypes.h"
#include "scemi_na_util.h"

NA_SCEMI

int main(int argc, char **argv) {
    NA_INIT(host);
    X x; x.v = 181;
    XF xf; 
    xf.v = 1.2;
    xf.a = 1;
    for(unsigned i=0; i<4; i++) 
        xf.b[i] = 1;
    for(unsigned i=0; i<3; i++) 
        xf.c[i] = 1.2;
    for(unsigned i=0; i<2; i++) 
        xf.e[i] = 1.2;
    xf.d = 1;
    xf.f = 1.1;

    WS ws,rws;
    ws.x = 180.77; ws.y = 106.83; ws.weight=1.3;
    Pixel p,rp;
    p.rgb[0] = 101; p.rgb[1]=102; p.rgb[2]=103;
    
    const unsigned items_to_send = 4;
    for(int i=0; i<items_to_send; i++) {
        SEND(X, x, 0, 1, echo);
        X rx;
        RECV(X, rx, 0, 1, echo);
        std::cout<< "->\tx="<<x<<std::endl;
        std::cout<< "<-\trx="<<rx << std::endl;
        
        SEND(XF, xf, 0, 1, echof);
        XF rxf;
        RECV(XF, rxf, 0, 1, echof);
        std::cout<< "->\txf="<<xf <<std::endl;
        std::cout<<"<-\trxf="<<rxf << std::endl;

        SEND(WS, ws, 0, 1, echof);
        RECV(WS, rws, 0, 1, echof);
        std::cout<< "->\tws="<<ws <<std::endl;
        std::cout<<"<-\trws="<<rws << std::endl;
        SEND(Pixel, p, 0, 1, echof);
        RECV(Pixel, rp, 0, 1, echof);
        std::cout<< "->\tp="<<p <<std::endl;
        std::cout<<"<-\trp="<<rp << std::endl;
    }
#if 0
    WS center;
    center.x=180.77; center.y=106.83; center.weight=1.3; 
    SEND(WS,center, 0, 1, sink0);
    sleep(5);
#endif
    return 0;
}
