/*
  postgres_result.cpp

  wrapper around PGresult
*/

#include "postgres_result.h"
#include "oids.h"
#include <cstring>

PostgresResult::PostgresResult(PGresult *res) {
  _result = res;
    if (!(PQresultStatus(_result) == PGRES_TUPLES_OK || PQresultStatus(_result) == PGRES_COMMAND_OK)) throw PQresultErrorMessage(_result);
}

PostgresResult::PostgresResult(PostgresResult &pgres) {
  _result = PQcopyResult(pgres._result, PG_COPYRES_ATTRS | PG_COPYRES_TUPLES | PG_COPYRES_NOTICEHOOKS | PG_COPYRES_EVENTS);
}

PostgresResult::~PostgresResult() {
  PQclear(_result);
}

bool PostgresResult::null_at(size_t r, size_t c) const {
  return PQgetisnull(_result, r, c);
}

bool PostgresResult::json() const {
  return (PQnfields(_result) == 1 && PQntuples(_result) == 1 && PQftype(_result, 0) == JSONOID && strcmp(PQfname(_result, 0), json_col.c_str()) == 0);
}

std::string PostgresResult::at(size_t r, size_t c) const {
  char *value = PQgetvalue(_result, r, c);
  int length = PQgetlength(_result, r, c);

  return std::string(value, length);
}

size_t PostgresResult::number_rows() const {
  return (size_t)PQntuples(_result);
}

size_t PostgresResult::number_cols() const {
  return (size_t)PQnfields(_result);
}

std::string PostgresResult::col_name(size_t idx) const {
  return std::string(PQfname(_result, idx));
}

Oid PostgresResult::col_oid(size_t idx) const {
  return PQftype(_result, idx);
}

bool PostgresResult::col_binary(size_t c) const {
  return PQfformat(_result, c) == 0;
}
