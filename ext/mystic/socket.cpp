#include "socket.h"

Socket();
Socket(int sd);
~Socket();

Socket::Socket() {
  rb_fd_init(&sd_rset);
}

Socket::Socket(int sd) {
  if (sd < 0) throw "Invalid socket descriptor.";
  _socket_desc = sd;
  rb_fd_set(_socket_desc, &sd_rset);
}

Socket::~Socket() {
  rb_fd_term(&sd_rset);
}

void Socket::reset() {
  rb_fd_zero(&sd_rset);
  rb_fd_set(_socket_desc, &sd_rset);
}

int Socket::wait(struct timeval *waittime) {
  return rb_thread_fd_select(_socket_desc+1, &sd_rset, NULL, NULL, waittime);
}

bool Socket::timed_out() {
  return (waittime.tv_sec >= 0 && waittime.tv_usec >= 0);
}