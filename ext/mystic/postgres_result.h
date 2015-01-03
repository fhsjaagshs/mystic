/*
  postgres_result.h

  wrapper around PGresult
*/

#include <iostream>
#include "libpq-fe.h"

class PostgresResult {
public:
  std::string json_col;
  
  PostgresResult(PGresult *res);
  PostgresResult(PostgresResult &pgres);
  ~PostgresResult();
  
  bool json() const;
  
  std::string at(size_t r, size_t c) const;
  bool null_at(size_t r, size_t c) const;
  
  size_t number_rows() const;
  size_t number_cols() const;
  
  std::string col_name(size_t idx) const;
  Oid col_oid(size_t idx) const;
  bool col_binary(size_t idx) const;
private:
  PGresult *_result;
};