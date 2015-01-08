#include "timeout.h"

Timeout::Timeout(double sec) {
  _timeout.tv_sec = (time_t)sec;
  _timeout.tv_usec = (suseconds_t)((sec-(long)sec)*1e6);
}

void Timeout::update() {
  gettimeofday(&currtime, NULL);
  timersub(&aborttime, &currtime, &waittime);
}

void Timeout::start() {
	gettimeofday(&currtime, NULL);
	timeradd(&currtime, &_timeout, &aborttime);
}

struct timeval Socket::get_timeval() {
  return waittime;
}

bool Socket::timed_out() {
  return (waittime.tv_sec >= 0 && waittime.tv_usec >= 0);
}