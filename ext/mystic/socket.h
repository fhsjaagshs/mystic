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
  Socket(int sd);
  ~Socket();
  int select_readable(struct timeval *waittime);
  int select_writeable(struct timeval *waittime);
  int select_errored(struct timeval *waittime);
private:
  int _socket_desc;
  fd_set file_descs;
  Socket(); // hide this useless constructor
};