#include<iostream>
template<class T, unsigned depth_> 
class MyFIFO
{
public:
    int front, rear;
    T array_store[depth_];
    MyFIFO()
    {
        front = -1;
        rear = -1;
    }
    
#if 0
    T& operator[] (int index){
      std::cout << "T& [] called" << std::endl;
      if (notEmpty()) {
        if (rear+index > front) {
          std::cout << " index access into Fifo outside bounds" << std::endl;
        }
        return array_store[rear+index];
      } else {
        std::cout << "invalid index access [" << index << "], Fifo is empty" << std::endl;
      }
      return array_store[0];
    }
    const T& operator[](int index) const {
      std::cout << "T& [] const const called" << std::endl;
      return array_store[rear+index];
    }
    T* operator&(){ 
      if (-1 == rear) 
      return &array_store[0];
      else
      return &array_store[rear];
    }
#endif 
    
    bool notEmpty () const { return front != -1; }
    bool notFull()  { return front != depth_-1; }
    T first() { 
      if (notEmpty()) {
        return array_store[rear];
      } else {
        std::cout << "first():: Fifo is empty" << std::endl;
      }
    };

    void enq(T a)
    {
        if(notFull())
        {
            array_store[++front] = a;
            if(rear == -1)
                rear = 0;
        }
        else
            std::cout << "enq():: Fifo is full" << std::endl;
    }

    void deq()
    {
        if(notEmpty())
        {
            if(rear == front)
                rear = front = -1;
            else
                rear++;
        }
        else
            std::cout << "deq():: Fifo is empty" << std::endl;
    }

    void display ()
    {
#if 0
        if(notEmpty())
        {
            for(int i=rear;i<=front;i++)
                std::cout << array_store[i] << " ";
            std::cout << std::endl;
        }
        else
            std::cout << "display():: Fifo is empty" << std::endl;
#else
        std::cout << display(std::cout);
#endif 
    }
    std::ostream& display(std::ostream &os) const{
      if(notEmpty())
      {
        for(int i=rear;i<=front;i++)
          os << array_store[i] << " ";
        os << std::endl;
      }
      else {
        os << "display():: Fifo is empty" << std::endl;
      }
      return os;
    }
};
template<class T, unsigned depth_>
inline std::ostream& operator<<( std::ostream& os, const MyFIFO<T, depth_>& f) {
    // os << f.display(os) ;
    return os;
}


