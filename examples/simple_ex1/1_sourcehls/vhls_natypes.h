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
  
  struct X {
      ap_uint<25> v;
    static unsigned size() { return 25;};
#if 0
    volatile X& operator = (const X& a) volatile {
           this->v = a.v;
      return *this;
    }
#endif
  };
  typedef struct X X;
  struct WS {
      ap_ufixed<32,16> weight;
      ap_ufixed<32,16> x;
      ap_ufixed<32,16> y;
    static unsigned size() { return 96;};
#if 0
    volatile WS& operator = (const WS& a) volatile {
           this->weight = a.weight;
           this->x = a.x;
           this->y = a.y;
      return *this;
    }
#endif
  };
  typedef struct WS WS;
  struct Pixel {
      ap_uint<8> rgb[3];
    static unsigned size() { return 24;};
#if 0
    volatile Pixel& operator = (const Pixel& a) volatile {
           for(unsigned i=0; i<3; i++) { this->rgb[i] = a.rgb[i]; }
      return *this;
    }
#endif
  };
  typedef struct Pixel Pixel;
  struct XF {
      float v;
      ap_uint<25> a;
      ap_uint<12> b[4];
      float c[3];
      double e[2];
      uint32_t d;
      ap_ufixed<32,16> f;
    static unsigned size() { return 393;};
#if 0
    volatile XF& operator = (const XF& a) volatile {
           this->v = a.v;
           this->a = a.a;
           for(unsigned i=0; i<4; i++) { this->b[i] = a.b[i]; }
           for(unsigned i=0; i<3; i++) { this->c[i] = a.c[i]; }
           for(unsigned i=0; i<2; i++) { this->e[i] = a.e[i]; }
           this->d = a.d;
           this->f = a.f;
      return *this;
    }
#endif
  };
  typedef struct XF XF;
  struct NATaskInfo {
      uint8_t node_id;
    static unsigned size() { return 8;};
#if 0
    volatile NATaskInfo& operator = (const NATaskInfo& a) volatile {
           this->node_id = a.node_id;
      return *this;
    }
#endif
  };
  typedef struct NATaskInfo NATaskInfo;
// convenience ostreams (FShow like)
inline std::ostream& operator<<( std::ostream& os, const X& f) {
    os <<"X { ";
       
            os << "v: "<< HEX_STREAM_MANIP32 <<f.v<<" ";

    os << "}";
    return os;
}
inline std::ostream& operator<<( std::ostream& os, const WS& f) {
    os <<"WS { ";
       
            os << "weight: "<< HEX_STREAM_MANIP32 <<f.weight<<" ";

       
            os << "x: "<< HEX_STREAM_MANIP32 <<f.x<<" ";

       
            os << "y: "<< HEX_STREAM_MANIP32 <<f.y<<" ";

    os << "}";
    return os;
}
inline std::ostream& operator<<( std::ostream& os, const Pixel& f) {
    os <<"Pixel { ";
       
           os << "rgb: <V ";
           for(unsigned i=0; i<3; i++) {
               //os << i <<": "<< f.rgb[i] <<" "; // with index
#if defined(TYPES_PRINT_AS_HEX)
               os << std::hex << f.rgb[i] <<", "; // hex
#else
               os << +f.rgb[i] <<", "; // default
#endif
           } // for 
           os << ">, ";

    os << "}";
    return os;
}
inline std::ostream& operator<<( std::ostream& os, const XF& f) {
    os <<"XF { ";
       
            os << "v: "<< HEX_STREAM_MANIP32 <<f.v<<" ";

       
            os << "a: "<< HEX_STREAM_MANIP32 <<f.a<<" ";

       
           os << "b: <V ";
           for(unsigned i=0; i<4; i++) {
               //os << i <<": "<< f.b[i] <<" "; // with index
#if defined(TYPES_PRINT_AS_HEX)
               os << std::hex << f.b[i] <<", "; // hex
#else
               os << +f.b[i] <<", "; // default
#endif
           } // for 
           os << ">, ";

       
           os << "c: <V ";
           for(unsigned i=0; i<3; i++) {
               //os << i <<": "<< f.c[i] <<" "; // with index
#if defined(TYPES_PRINT_AS_HEX)
               os << std::hexfloat << f.c[i] <<", "; // hex
#else
               os << std::fixed << f.c[i] <<" "; // fixed
#endif
           } // for 
           os << ">, ";

       
           os << "e: <V ";
           for(unsigned i=0; i<2; i++) {
               //os << i <<": "<< f.e[i] <<" "; // with index
#if defined(TYPES_PRINT_AS_HEX)
               os << std::hexfloat << f.e[i] <<", "; // hex
#else
               os << std::fixed << f.e[i] <<" "; // fixed
#endif
           } // for 
           os << ">, ";

       
            os << "d: "<< HEX_STREAM_MANIP32 <<f.d<<" ";

       
            os << "f: "<< HEX_STREAM_MANIP32 <<f.f<<" ";

    os << "}";
    return os;
}
inline std::ostream& operator<<( std::ostream& os, const NATaskInfo& f) {
    os <<"NATaskInfo { ";
       
            os << "node_id: "<< HEX_STREAM_MANIP32 <<f.node_id<<" ";

    os << "}";
    return os;
}

#endif

