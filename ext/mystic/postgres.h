/*
  postgres.h

  A C++ class to wrap libpq
*/

#include "libpq-fe.h"

using namespace std;

class Postgres {
public:
  Postgres::Postgres();
  Postgres::~Postgres();
  
  void Postgres::connect(char **keys, char **values);
  void Postgres::disconnect();
  
  PGresult * Postgres::execute(string *query);
  
  string * Postgres::escape_string(string *string);
  string * Postgres::escape_literal(string *literal);
  string * Postgres::escape_identifier(string *identifier);
  
  int Postgres::client_encoding();
private:
  PGconn *_connection;
  
  char * Postgres::compose_format(size_t extra_alloc, const char *fmt, ...);
};
