/*
 * nabase.h
 */

#ifndef NABASE_H
#define NABASE_H

#include <bitset>
#include <iostream>
#include <iterator> 
#include <string>
#include <vector>
#include <algorithm> 
#include <utility> 
#define DEST_ADDR_WIDTH 4
#define VC_WIDTH 1
#define FLIT_DATA_WIDTH 64

typedef std::bitset<FLIT_DATA_WIDTH> FlitData;
class Flit {
public:
  std::bitset<1>                valid;
  std::bitset<1>                is_tail;
  std::bitset<DEST_ADDR_WIDTH>  destAddr;
  std::bitset<VC_WIDTH>         vc;
  FlitData                      data;   
};
std::ostream& operator<<(std::ostream& stdout, const Flit& o) {
  stdout << " valid: " << o.valid 
    << ", tail: " << o.is_tail 
    << ", dest: " << o.destAddr 
    << ", vc: "   << o.vc 
    << ", data: " << o.data;
}

class Packet {
  std::bitset<DEST_ADDR_WIDTH>  destAddr;
  std::bitset<VC_WIDTH>         vc;
  std::vector<Flit>             toFlits();
};

class FromNetwork {
};
class ToNetwork {
};

#endif /* !NABASE_H */
