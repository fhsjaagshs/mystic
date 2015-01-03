/*
  postgres.h

  A C++ class to wrap libpq
*/

#include <iostream>
#include "libpq-fe.h"

class Postgres {
public:
  Postgres();
  ~Postgres();
  
  bool connected();
  void connect(char **keys, char **values);
  void disconnect();
  
  PGresult * execute(std::string query);
  
  std::string escape_string(std::string string);
  std::string escape_literal(std::string literal);
  std::string escape_identifier(std::string identifier);
  
  void reset();
  
  int client_encoding();
private:
  PGconn *_connection;
  const char * compose_format(size_t extra_alloc, const char *fmt, ...);
};
