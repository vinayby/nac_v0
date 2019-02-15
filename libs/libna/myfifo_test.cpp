#include "myfifo.h"
class TS {
public:
  int a;
  TS (int a) : a(a) {};
  TS() {};
};
inline std::ostream& operator<<(std::ostream &os, const TS &ts) {
  os << "TS.a := "<<ts.a << std::endl;
  return os;
}

int main()
{
    MyFIFO<TS, 5> q;
    q.enq(TS(1));
    q.enq(TS(2));
    q.enq(TS(3));
    q.enq(TS(4));
    q.enq(TS(5));
    q.enq(TS(6));

    q.display();
    return 0;

    TS *a = &q.array_store[q.rear];
    for(unsigned i=0; i<5; i++) {
      std::cout << a[i] <<" " << std::endl;
    }
    for(unsigned i=0; i<5; i++) {
      std::cout << q.first() << std::endl;
      q.deq();
    }
   
   MyFIFO<TS, 1> p;
   p.enq(TS(101));
   std::cout << p.first() << std::endl;
   p.deq();
   p.deq();
}

