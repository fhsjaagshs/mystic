/*
  socket.h

  A C++ class to wrap a socket
*/

#include <iostream>

class Socket {
public:
  Socket();
  Socket(int sd);
  ~Socket();
private:
  int _socket_desc;
  rb_fdset_t sd_rset;
  
  struct timeval aborttime={0,0}, currtime, waittime;
};