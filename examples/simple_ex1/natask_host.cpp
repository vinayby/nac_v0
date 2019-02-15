//NO_AUTOREPLACE
/*********** vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
*/


NA_MPI;

#include "mpimodel.h"

void natask_host(unsigned na_task_id, const char *taskname)
{
    NATASK_BEGIN;

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
    NATASK_END;
}
