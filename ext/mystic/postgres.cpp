/*
  postgres.cpp

  A C++ class to wrap libpq
*/

#include "postgres.h"
#include "pg_config_manual.h"

char * Postgres::compose_format(size_t extra_alloc, const char *fmt, ...) {
  va_list args;
  char buf[strlen(fmt)+20+extra_alloc];
  
  va_start(args, fmt);
  vsprintf(buf,fmt,args);
  va_end(args);
  
  return buf;
}

Postgres::Postgres() {
  _connection = NULL;
}

Postgres::~Postgres() {
  disconnect();
}

void Postgres::connect(char **keys, char **values) {
  if (_connection) {
    // TODO: disconnect
  }
  
  // TODO: check each pair & escape values
  
  PGconn *conn = PQconnectdbParams(keys, values, 1);
  if (!conn) throw "Failed to connect to database.";
  if (PQstatus(conn) == CONNECTION_BAD) throw PQerrorMessage(conn);
  
  _connection = conn;
}

void Postgres::disconnect() {
  if (_connection) PQfinish(_connection);
  _connection = NULL;
}

PGresult * Postgres::execute(string *query) {
  if (query->length() == 0) throw "Empty query";
  if (query->at(query->length()-1) != ';') query << ';'
  
  return PQexec(_connection, query->c_str());
}

string * Postgres::escape_string(string *string) {
  int *error;
  char *buf = malloc(sizeof(char)*(string->length()*2+1));
  size_t size = PQescapeStringConn(_connection, buf, string->c_str(), string->length(), error);
  
  if (error) {
    free(buf);
    throw PQerrorMessage(_connection);
    return NULL;
  } else {
    string *escaped = new string(buf);
    free(res);
    return escaped;
  }
}

string * Postgres::escape_literal(string *literal) {
  char *res = PQescapeLiteral(_connection, literal->c_str(), literal->length());
  if (!res) {
    throw compose_format(literal->length(), "Failed to escape string '%s'", literal->c_str());
    return NULL;
  } else {
    string *escaped = new string(res);
    PQfreemem(res);
    return escaped;
  }
}

string * Postgres::escape_identifier(string *identifier) {
  if (identifier->length() > NAMEDATALEN) throw "Identifier is longer than the the limit, NAMEDATALEN.";

  // result size at most NAMEDATALEN*2 plus surrounding double-quotes
  char *buffer = malloc(sizeof(char)*(NAMEDATALEN*2+2));
  size_t j = 0; // length of escaped string
  
  buffer[j++] = '"';
  for (size_t i = 0; i < identifier->length(); i++) {
    if (identifier[i] == '"') buffer[j++] = '"';
    buffer[j++] = identifier[i];
  }
  
  buffer[j++] = '"';

  string * escaped = new string(buffer);
    
  free(buffer);
    
  return escaped;
}

void Postgres::reset() {
  PQreset(_connection);
}

int Postgres::client_encoding() {
  return PQclientEncoding(_connection);
}