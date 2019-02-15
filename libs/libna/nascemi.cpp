/*********** vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4 
 * nascemi.cpp
 */
#include <iostream>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>                 
#include <stdlib.h>                 
#include <unistd.h>
#include <sys/time.h>
#include <time.h>
#include<cstdio>

#include "nascemi.h"
#include "ap_int.h"
#define MAX_FLITS_PER_SEND 32

void NaSceMi::init() {
    params = new SceMiParameters("scemi.params");
    scemi = SceMi::Init(SceMi::Version(SCEMI_VERSION_STRING), params);
    shutdown = new ShutdownXactor("", "scemi_shutdown", scemi);
    sthread = new SceMiServiceThread(scemi);
    putFlit = new InportProxyT<Flit>("", "scemi_putFlit_inport", scemi);
    getFlit = new OutportProxyT<Flit>("", "scemi_getFlit_outport", scemi);
    putRawData = new InportProxyT<NARawData>("", "scemi_putRawData_inport", scemi);
    getRawData = new OutportProxyT<NARawData>("", "scemi_getRawData_outport", scemi);
    set_callback();
    port_id = 2;
}
void NaSceMi::set_callback() {
    getFlit->setCallBack(getFlit_cb, &cbd);
    getRawData->setCallBack(getRawData_cb, &cbd_raw);
}
unsigned NaSceMi::flits_in_datatype(unsigned sizeof_type_in_bits) {
    unsigned fw = flit_width_;
    return 1+unsigned((sizeof_type_in_bits+fw-1)/fw); 
}

unsigned NaSceMi::set_n_parameters() {
    Flit f;
    flit_width_     = f.m_data.getBitSize();
    address_width_  = f.m_destAddr.getBitSize();
    fhdr_srcaddr_offset_ = flit_width_ - address_width_;
    fhdr_typetag_offset_ = flit_width_ - address_width_ - typetag_bitwidth;
}
void NaSceMi::cleanup() {
	shutdown->blocking_send_finish();
	sthread->stop();
	sthread->join();
	SceMi::Shutdown(scemi);
        delete params;
        delete shutdown;
        delete putFlit;
        delete getFlit;
        delete putRawData;
        delete getRawData;
	delete sthread;
}
void NaSceMi::getRawData_cb(void* userdata, const NARawData& resp)
{
    CallbackDataRaw* cbd_raw = (CallbackDataRaw*)userdata;
    cbd_raw->qf.push(resp);
}
void NaSceMi::getFlit_cb(void* userdata, const Flit& resp)
{
    CallbackData* cbd = (CallbackData*)userdata;
    cbd->qf.push(resp);
}
int NaSceMi::send_(uint8_t to, uint8_t type, uint64_t length_bits, void *data) {
    send(to, type, length_bits/8, data);  
}
int NaSceMi::recv_(uint8_t to, uint8_t type, uint64_t length_bits, void *data) {
    recv(to, type, length_bits/8, data);  
}

int NaSceMi::recv(uint8_t from, uint8_t type, uint64_t length_bytes, void *data) {
    unsigned length = length_bytes;
    unsigned count = 1+ (length*8+flit_width_-1)/(flit_width_); /* bytes/bytes */; 
    while(cbd.qf.size() < count) { sleep(1); /* printf(".");fflush(stdout);*/ /* WAIT */}
    Flit f0 = cbd.qf.front();  cbd.qf.pop();
    ap_uint<512> pload = 0;
    for(unsigned i=0; i<count-1; i++){
        Flit f = cbd.qf.front();  cbd.qf.pop();
        //std::cout << " NaSceMi::recvnew f=" << f << std::endl;
        pload(flit_width_*(i+1)-1,i*flit_width_) = f.m_data;
    }
    *(ap_uint<512> *) data = pload;
}
int NaSceMi::recvl(uint8_t from, uint8_t type, uint64_t length_bits, unsigned nelems, void *data) {
    unsigned length_bytes = length_bits/8;
    unsigned length = length_bytes;
    unsigned count = 1+ (length*8+flit_width_-1)/(flit_width_); /* bytes/bytes */; 
    while(cbd.qf.size() < 1+nelems*(count-1)) { sleep(1); printf(".");fflush(stdout); /* WAIT */}
    Flit f0 = cbd.qf.front();  cbd.qf.pop();
#if defined(NA_SCEMI_DEBUG)
    std::cout << " NaSceMi::recv f0 =" << f0 << std::endl;
#endif
    ap_uint<512> pload = 0;
    ap_uint<512> *p_pload = (ap_uint<512> *) data;
    for(unsigned k = 0; k<nelems; k++) {
        for(unsigned i=0; i<count-1; i++){
            Flit f = cbd.qf.front();  cbd.qf.pop();
#if defined(NA_SCEMI_DEBUG)
            std::cout << " NaSceMi::recv f=" << f << std::endl;
#endif
            pload(flit_width_*(i+1)-1,i*flit_width_) = f.m_data;
        }
        p_pload[k] = pload;
    }
    //*(ap_uint<512> *) data = pload;
}

int NaSceMi::test_bulkio_loopback_mode() {
    NARawData rd;
    //send
    for(unsigned i=100; i<100+12; i++) {
        rd.m_data = i;
        rd.m_address = i%9;
        rd.m_typetag = i%4;
        rd.m_nelems_packed = 1;
        rd.m_htmark = P_HEADTAIL;
        putRawData->sendMessage(rd);
    }
    //recv 
    while(cbd_raw.qf.size() < 12)  { sleep(1); printf(".");fflush(stdout); /* WAIT */} 
    for(unsigned i=100; i<100+12; i++) {
        NARawData r = cbd_raw.qf.front(); cbd_raw.qf.pop();
        std::cout << "r:"<<i-100 << " " << r << std::endl;
    }
}
int NaSceMi::recvRAW(uint8_t from, uint8_t type, uint64_t length_bits, void *data) {
    ap_uint<512> pload = 0;
    unsigned N = (length_bits + 31)/32;
    while (cbd_raw.qf.size() < 1) { sleep(1);printf(".");fflush(stdout); /* WAIT */}
    NARawData r = cbd_raw.qf.front(); cbd_raw.qf.pop();
    for(unsigned i=0; i<N; i++){
        pload(32*(i+1)-1,i*32) = r.m_data.getWord(i);
    }
    *(ap_uint<512> *) data = pload;

}
int NaSceMi::sendRAW(uint8_t to, uint8_t type, uint64_t length_bits, void *data) {
    ap_uint<512> &pload = *(ap_uint<512> *) data;
    unsigned N = (length_bits + 31)/32;
    NARawData rd;
    rd.m_address = to;
    rd.m_typetag = type;
    rd.m_nelems_packed = 1;
    rd.m_htmark = P_HEADTAIL;
    for(unsigned i=0; i<N; i++){
        rd.m_data.setWord(i, pload.range((i+1)*32-1, i*32));
    }
    putRawData->sendMessage(rd);
}

int NaSceMi::sendl(uint8_t to, uint8_t type, uint64_t length_bits, unsigned nelems, void *data) 
{
    unsigned length_bytes = length_bits/8;
    unsigned length = length_bytes;
    static Flit f[MAX_FLITS_PER_SEND];
    unsigned count = 1+ (length*8+flit_width_-1)/(flit_width_); // bytes / bytes ; 
    f[0].m_valid = 1;
    f[0].m_is_tail = 0;
    f[0].m_vc = 0;
    f[0].m_destAddr = to;
    //TODO for flit_width_s > 64
    f[0].m_data = (uint64_t) port_id << fhdr_srcaddr_offset_ | (uint64_t) type << fhdr_typetag_offset_;
    //ap_uint<512> &pload = *(ap_uint<512> *) data;
    ap_uint<512> *p_pload = (ap_uint<512> *) data;
    putFlit->sendMessage(f[0]);
#if defined(NA_SCEMI_DEBUG)
    std::cout << "sendl::f0 " << f[0] << std::endl;
#endif
    for(unsigned k = 0; k<nelems; k++) {
        for (int i = 0; i < count; ++i) {
            f[i+1].m_valid = 1;
            f[i+1].m_is_tail = 0;
            if ((i == count - 2) && (k==nelems-1))
                f[i+1].m_is_tail = 1;
            f[i+1].m_vc = 0;
            f[i+1].m_destAddr = to;
            uint64_t e_ =  p_pload[k].range(flit_width_*(i+1)-1,i*flit_width_); // TODO no path from bw>64 from ap_uint to BitT
            f[i+1].m_data = e_;
        }
        for (int i = 1; i < count; ++i) {
            putFlit->sendMessage(f[i]);
        }
    }
}
int NaSceMi::send(uint8_t to, uint8_t type, uint64_t length_bytes, void *data) 
{
    unsigned length = length_bytes;
    static Flit f[MAX_FLITS_PER_SEND];
    unsigned count = 1+ (length*8+flit_width_-1)/(flit_width_); // bytes / bytes ; 
    f[0].m_valid = 1;
    f[0].m_is_tail = 0;
    f[0].m_vc = 0;
    f[0].m_destAddr = to;
    //TODO for flit_width_s > 64
    f[0].m_data = (uint64_t) port_id << fhdr_srcaddr_offset_ | (uint64_t) type << fhdr_typetag_offset_;
    ap_uint<512> &pload = *(ap_uint<512> *) data;

    for (int i = 0; i < count; ++i) {
        f[i+1].m_valid = 1;
        f[i+1].m_is_tail = 0;
        if (i == count - 2)
            f[i+1].m_is_tail = 1;
        f[i+1].m_vc = 0;
        f[i+1].m_destAddr = to;
        uint64_t e_ =  pload.range(flit_width_*(i+1)-1,i*flit_width_); // TODO no path from bw>64 from ap_uint to BitT
        f[i+1].m_data = e_;
    }
    for (int i = 0; i < count; ++i) {
        putFlit->sendMessage(f[i]);
    }
}



