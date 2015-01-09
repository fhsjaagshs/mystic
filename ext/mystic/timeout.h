/*
  timeout.h

  A C++ class to wrap a timeval
*/

#include <sys/time.h>

class Timeout {
public:
    Timeout();
    Timeout(double sec);
    void update();
    void start();
    struct timeval * get_timeval();
    bool zero();
    bool timed_out();
private:
    struct timeval _timeout;
    struct timeval _aborttime;
    struct timeval _currtime;
    struct timeval _waittime;
};