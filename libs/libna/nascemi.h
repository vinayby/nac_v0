/*
 * nascemi.h
 *
 * FLIT level I/O over SceMI
 *   - this is an low-level I/O between a software task and other tasks on the network
 *   - TODO: the interface between the software task and the corresponding
 *   placeholder on the network should be at a payload level instead of Flit
 *   level.
 */

#ifndef NASCEMI_H
#define NASCEMI_H
#include <stdint.h> // cstdint is tied up in c++11, not compatible with bsc
#include "SceMiHeaders.h"
#include <queue>
typedef enum {P_NONE, P_HEAD, P_TAIL, P_HEADTAIL} E_HTMark;
class NaSceMi {
public:
    /* scemi stuff */
    SceMiParameters *params;
    SceMi *scemi;
    ShutdownXactor *shutdown;
    SceMiServiceThread* sthread;
    InportProxyT<Flit>* putFlit;
    OutportProxyT<Flit>* getFlit;

    InportProxyT<NARawData>* putRawData;
    OutportProxyT<NARawData>* getRawData;

    /* na application (specific) parameters */
    unsigned port_id; // one port per NaSceMi object?
    unsigned typetag_bitwidth;
    unsigned flits_in_datatype(unsigned sizeof_type);
    unsigned get_flitwidth();
    unsigned flit_width_;
    unsigned address_width_;
    unsigned fhdr_srcaddr_offset_; 
    unsigned fhdr_typetag_offset_; 
    unsigned set_n_parameters();



    void init();
    void cleanup();

    /* io */
    int send(uint8_t toaddress, uint8_t type, uint64_t length_bytes, void *data);
    int recv(uint8_t fromaddress, uint8_t type, uint64_t length_bytes, void *data);
    int recv_(uint8_t fromaddress, uint8_t type, uint64_t length_bits, void *data);
    int send_(uint8_t toaddress, uint8_t type, uint64_t length_bits, void *data);
    int recvRAW(uint8_t from, uint8_t type, uint64_t length_bits, void *data);
    int sendRAW(uint8_t to, uint8_t type, uint64_t length_bits, void *data);
    int recvl(uint8_t from, uint8_t type, uint64_t length_bits, unsigned nelems, void *data);
    int sendl(uint8_t to, uint8_t type, uint64_t length_bits, unsigned nelems, void *data);

    int test_bulkio_loopback_mode();
    
    typedef struct callbackData
    {
      uint32_t* outstandingReqs;
      std::queue<Flit> qf;
    } CallbackData;
    typedef struct callbackDataRaw
    {
      uint32_t* outstandingReqs;
      std::queue<NARawData> qf;
    } CallbackDataRaw;
    
    void set_callback();

    CallbackData cbd;
    CallbackDataRaw cbd_raw;
  
    static void getFlit_cb(void* userdata, const Flit& resp);
    static void getRawData_cb(void* userdata, const NARawData& resp);
};

/* read exactly nmembs members of T; exactly and no more */
template <class T>
void read_nmembs(const char *fromfile, unsigned long nmembs, T *to, bool exactly) {
    FILE *fp = fopen(fromfile, "rb");
    if(NULL==fp) {perror(fromfile); exit(1);}
    unsigned nr = fread(to, sizeof(to[0]), nmembs, fp); 
    if(exactly) {
        fgetc(fp);
        if(nr != nmembs || !feof(fp)) {
            printf("%s: nr (%u) != nmembs (%u) eof:%d\n", fromfile, nr, nmembs, feof(fp));
            exit(1);
        }
    }else{
        if(nr != nmembs) {
            printf("%s: nr (%u) != nmembs (%u) \n", fromfile, nr, nmembs);
            exit(2);
        }
    }
}

#endif /* !NASCEMI_H */
