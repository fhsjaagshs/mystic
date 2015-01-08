#include "socket.h"

Socket::Socket() {
  file_descs = (fd_set *)malloc(sizeof(fd_set));
  FD_ZERO(file_descs);
}

Socket::Socket(int sd) {
  if (sd < 0) throw "Invalid socket descriptor.";
  _socket_desc = sd;
  FD_SET(_socket_desc, file_descs);
}

Socket::~Socket() {
  if (FD_ISSET(_socket_desc, file_descs)) FD_CLR(_socket_desc, file_descs);
  free(file_descs);
}

void Socket::reset() {
  FD_ZERO(file_descs);
  FD_SET(_socket_desc, file_descs);
}

int Socket::select_readable(struct timeval *waittime) {
  return select(_socket_desc+1, file_descs, NULL, NULL, waittime);
}

int Socket::select_writeable(struct timeval *waittime) {
  return select(_socket_desc+1, NULL, file_descs, NULL, waittime);
}

int Socket::select_errored(struct timeval *waittime) {
  return select(_socket_desc+1, NULL, NULL, file_descs, waittime);
}