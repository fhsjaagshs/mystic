/*
  timeout.h

  A C++ class to wrap a timeval
*/

#import <sys/time>

class Timeout {

private:
  struct timeval _timeout;
  struct timeval _aborttime={0,0};
  struct timeval _currtime
  struct timeval _waittime;
};