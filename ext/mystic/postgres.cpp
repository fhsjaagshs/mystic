/*
  postgres.cpp

  A C++ class to wrap libpq

  a couple of notes:
  1. Always use PQfreemem(), see http://www.postgresql.org/docs/9.4/static/libpq-misc.html
  2. Strings are not properly encoded to the client_encoding, but that's something that can wait
*/

#include "postgres.h"
#include "socket.h"
#include "timeout.h"
#include "pg_config_manual.h"
#include <cstring>
#include <string>
#include <cstdarg>

using namespace std;

const char * Postgres::compose_format(size_t extra_alloc, const char *fmt, ...) {
  va_list args;
  char buf[strlen(fmt)+20+extra_alloc];
  
  va_start(args, fmt);
  vsprintf(buf,fmt,args);
  va_end(args);
  
  std::string str(buf);
  
  return str.c_str();
}

Postgres::Postgres() {
  _connection = NULL;
}

Postgres::~Postgres() {
  disconnect();
}

bool Postgres::connected() {
  return _connection != NULL && PQstatus(_connection) == CONNECTION_OK;
}

void Postgres::connect(char **keys, char **values) {
  if (connected()) {
    disconnect();
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

PGresult * Postgres::execute(string query) {
  if (query.length() == 0) throw "Empty query";
  if (query[query.length()-1] != ';') query += ';';
  return PQexec(_connection, query.c_str());
}

string Postgres::escape_string(string str) {
  int error;
  char *buf = (char *)malloc(sizeof(char)*(str.length()*2+1));
  size_t size = PQescapeStringConn(_connection, buf, str.c_str(), str.length(), &error);
  
  string escaped(buf);
  PQfreemem(buf);
  
  if (error) throw PQerrorMessage(_connection);
  return escaped;
}

string Postgres::escape_literal(string literal) {
  char *res = PQescapeLiteral(_connection, literal.c_str(), literal.length());
  if (!res) {
    throw PQerrorMessage(_connection);
    return NULL;
  } else {
    string escaped(res);
    PQfreemem(res);
    return escaped;
  }
}

string Postgres::escape_identifier(string identifier) {
  if (identifier.length() > NAMEDATALEN) throw "Identifier is longer than the the limit, NAMEDATALEN.";

  // result size at most NAMEDATALEN*2 plus surrounding double-quotes plus null terminator
  char *buffer = (char *)malloc(sizeof(char)*(NAMEDATALEN*2+2));
  size_t j = 0; // length of escaped string
  
  buffer[j++] = '"';
  for (size_t i = 0; i < identifier.length(); i++) {
    if (identifier[i] == '"') buffer[j++] = '"';
    buffer[j++] = identifier[i];
  }
  buffer[j++] = '"';

  string escaped(buffer, j);
    
  free(buffer);
    
  return escaped;
}

map<const char *, string> Postgres::notifies(PGnotify *msg) {
  if (!msg) msg = PQnotifies(_connection);
  
  std::map<const char *, std::string> results;
  
  if (!msg) throw "No notification.";
  else {
    results["relname"] = string(msg->relname);
    results["extra"] = string(msg->extra);
    results["be_pid"] = to_string((long long)(msg->be_pid)); // uses long long for better compatibility (with Heroku) 
    PQfreemem(msg);
  }

  return results;
}

map<const char *, string> Postgres::wait_for_notify(double timeout) {
    int sd = PQsocket(_connection);
    
    if (PQconsumeInput(_connection) == 0) throw PQerrorMessage(_connection);
    
    PGnotify *msg;
    
    Socket s = Socket(sd);
    Timeout t = Timeout(timeout);

    t.start();

    while (!(msg = PQnotifies(_connection))) {
        t.update();
        
        if (!t.timed_out()) {
            int ret = s.select_readable(t.get_timeval());
            if (ret < 0) {
                throw ret;
            }
        } else {
            throw "Socket timed out.";
        }
      
      if (PQconsumeInput(_connection) == 0) throw PQerrorMessage(_connection); // Check for connection errors
    }

    return notifies(msg);
}

void Postgres::reset() {
  PQreset(_connection);
}

int Postgres::client_encoding() {
  return PQclientEncoding(_connection);
}
