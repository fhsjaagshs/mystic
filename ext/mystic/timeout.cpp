#include "timeout.h"

Timeout::Timeout(double sec) {
  _aborttime.tv_sec = 0;
  _aborttime.tv_usec = 0;
  _timeout.tv_sec = (time_t)sec;
  _timeout.tv_usec = (suseconds_t)((sec-(long)sec)*1e6);
}

void Timeout::update() {
  gettimeofday(&_currtime, NULL);
  timersub(&_aborttime, &_currtime, &_waittime);
}

void Timeout::start() {
	gettimeofday(&_currtime, NULL);
	timeradd(&_currtime, &_timeout, &_aborttime);
}

struct timeval * Timeout::get_timeval() {
  return &_waittime;
}

bool Timeout::timed_out() {
  return (_waittime.tv_sec >= 0 && _waittime.tv_usec >= 0);
}