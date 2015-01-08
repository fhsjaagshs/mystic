/*
  socket.h

  A C++ class to wrap a socket
*/

#include <iostream>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/select.h>

class Socket {
public:
  Socket();
  Socket(int sd);
  ~Socket();
  void Socket::reset();
  int Socket::select_readable(struct timeval *waittime);
  int Socket::select_writeable(struct timeval *waittime);
  int Socket::select_errored(struct timeval *waittime);
private:
  int _socket_desc;
  fd_set *file_descs;
};