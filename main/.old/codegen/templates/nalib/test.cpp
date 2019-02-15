/*
 * test.cpp
 * Copyright (C) 2016 vinay <vinay@dtnl>
 *
 * Distributed under terms of the MIT license.
 */


#include "nabase.h"
using std::bitset;
using std::string;

class Pair {
public:
  bitset<32> a;
  bitset<33> b;
  bitset<2> op;
private:
  //members: sizes, names; in order
  std::vector<std::pair<size_t, string>> m_zn = {{32, "a"}, {33, "b"}, {2, "b"}}; 
};

std::ostream& operator<<(std::ostream& stdout, const Pair& obj) {
  stdout << obj.a << ':' << obj.a.size() << ' ';
  stdout << obj.b << ':' << obj.b.size() << ' ';
  stdout << obj.op <<':' << obj.op.size() << ' ';
}
int main(int argc, char *argv[])
{
  Pair p;
  p.a = 0xa;
  p.b = 0xb;
  p.op = 2;
  std::cout<<'\n'<<p;
  std::cout<<' '<<sizeof(p);
  Flit f;
  std::cout<<'\n'<<f;
  return 0;
}

#if 0 //RANDOM1
static std::vector<std::string> split(std::string const & s, size_t chunksize)
{
#if 1
  size_t nchunks = s.size()/chunksize;
  int extra = s.size() - nchunks * chunksize;
  auto exs = std::string(extra, '0') + s; //zero-extend
  std::cout << "\nextras = " << extra <<'\n';
  auto it = exs.begin();
  std::vector<std::string> vt;
  std::cout << std::hex << bitset<8>(std::string(it, it+chunksize)).to_ulong()<<'\n';
  std::cout << std::hex << std::string(it, it+chunksize) <<'\n';
  it+=chunksize;
  return vt;
#else 
  size_t minsize = s.size()/count;
  int extra = s.size() - minsize * count;
  std::vector<std::string> tokens;
  for(size_t i = 0, offset=0 ; i < count ; ++i, --extra)
  {
    size_t size = minsize + (extra>0?1:0);
    if ( (offset + size) < s.size())
      tokens.push_back(s.substr(offset,size));
    else
      tokens.push_back(s.substr(offset, s.size() - offset));
    offset += size;
  }       
  return tokens;
#endif
}
std::string binstring_to_hexstring(std::string &bs){
  auto tokens = split(bs, 8);
  std::copy(tokens.begin(), tokens.end(), 
              std::ostream_iterator<std::string>(std::cout, ", "));
  //std::transform(tokens.begin(), tokens.end(), [](std::string byte) { return std::toupper(c); })
  return "";
}
#endif

