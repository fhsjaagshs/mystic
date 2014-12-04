/*
  postgres.c
  require "mystic/postgres"

  Interface to Postgres for Mystic
  p = Postgres.connect :database => "madeup" # other args too
  res = p.execute "SELECT * FROM table;" # res is an array of hashes, all perfectly coerced and trimmed into Ruby types
  p.disconnect!
*/

#include "postgres_ext.h"
#include <math.h>

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

VALUE rb_mMystic = Qnil;
VALUE m_cPostgres = Qnil;
VALUE mp_cError = Qnil;
VALUE m_Date = Qnil;
VALUE m_DateTime = Qnil;
VALUE m_REPR_COL = Qnil;

VALUE coerced_value(PGresult *result, size_t r, size_t c, int pg_encoding);

void Init_postgres_ext() {
    rb_mMystic = rb_define_module("Mystic");
    m_cPostgres = rb_define_class_under(rb_mMystic, "Postgres", rb_cObject);
    mp_cError = rb_define_class_under(m_cPostgres, "Error", rb_eStandardError);
    rb_define_alloc_func(m_cPostgres, postgres_allocate);
    rb_define_method(m_cPostgres, "initialize", RUBY_METHOD_FUNC(postgres_initialize), -1);
    rb_define_method(m_cPostgres, "disconnect!", RUBY_METHOD_FUNC(postgres_disconnect), 0);
    rb_define_method(m_cPostgres, "execute", RUBY_METHOD_FUNC(postgres_exec), 1);
    rb_define_method(m_cPostgres, "valid?", RUBY_METHOD_FUNC(postgres_valid), 0);
    rb_define_method(m_cPostgres, "escape_string", RUBY_METHOD_FUNC(postgres_escape_string), 1);
    rb_define_method(m_cPostgres, "escape_literal", RUBY_METHOD_FUNC(postgres_escape_literal), 1);
    rb_define_method(m_cPostgres, "escape_identifier", RUBY_METHOD_FUNC(postgres_escape_identifier), 1);
    rb_define_singleton_method(m_cPostgres, "escape_identifier", RUBY_METHOD_FUNC(postgres_escape_identifier), 1);
    
    rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("date"));
    m_Date = rb_const_get(rb_cObject, rb_intern("Date"));
    m_DateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));
    
    m_REPR_COL = rb_const_get(rb_mMystic, rb_intern("REPR_COL"));
}

// GC Free
static void postgres_gc_free(PGconn *conn) {
  if (conn) PQfinish(conn);
  conn = NULL;
}

static VALUE postgres_allocate(VALUE klass) {
	return Data_Wrap_Struct(klass, NULL, postgres_gc_free, NULL);
}

/*
  Connections
*/

static VALUE postgres_disconnect(VALUE self) {
  postgres_gc_free(DATA_PTR(self));
  return Qnil;
}

static VALUE postgres_initialize(int argc, VALUE *argv, VALUE self) {
  Check_Type(self, T_DATA);
  
  if (argc != 1) rb_raise(rb_eArgError, "Invalid arguments.");

  Check_Type(argv[0], T_HASH);
  
  VALUE connstr = rb_funcall(self, rb_intern("connstr"), 1, argv[0]);
  
  PGconn *conn = PQconnectdb(StringValueCStr(connstr));
  
  if (!conn) rb_raise(mp_cError, "Failed to create a connection.");
  if (PQstatus(conn) == CONNECTION_BAD) rb_raise(mp_cError, "%s",PQerrorMessage(conn));

  DATA_PTR(self) = conn;
  rb_iv_set(self, "@options", argv[0]);
  return self;
}

static VALUE postgres_valid(VALUE self) {
  return (DATA_PTR(self) && PQstatus(DATA_PTR(self)) == CONNECTION_OK) ? Qtrue : Qfalse;
}

/*
  Escaping
*/

static VALUE postgres_escape_string(VALUE self, VALUE in_str) {
  Check_Type(in_str, T_STRING);
  
  int error;
  char *escaped = malloc(sizeof(char)*(RSTRING_LEN(in_str) * 2 + 1));
  size_t size = PQescapeStringConn(DATA_PTR(self), escaped, RSTRING_PTR(in_str), RSTRING_LEN(in_str), &error);
  
  VALUE result = Qnil;
  
  if (!error) result = rb_str_new(escaped,size);
  free(escaped);
  if (error) rb_raise(mp_cError, "%s", PQerrorMessage(DATA_PTR(self)));

  encode(PQclientEncoding(DATA_PTR(self)), result, true);
  OBJ_INFECT(result, in_str);
  
  return result;
}

static VALUE postgres_escape_literal(VALUE self, VALUE in_str) {
  Check_Type(in_str, T_STRING);
  
  char *res = PQescapeLiteral(DATA_PTR(self), RSTRING_PTR(in_str), RSTRING_LEN(in_str));
  if (!res) rb_raise(mp_cError, "Failed to escape string %s as a literal: %s", StringValueCStr(in_str),PQerrorMessage(DATA_PTR(self)));
  
  VALUE ret = rb_str_new2(res);
  PQfreemem(res);
  encode(PQclientEncoding(DATA_PTR(self)), ret, true);
  OBJ_INFECT(ret, in_str);
  return ret;
}

static VALUE postgres_escape_identifier(VALUE self, VALUE in_str) {
  Check_Type(in_str, T_STRING);
  
	char *str = RSTRING_PTR(in_str);
  size_t str_len = RSTRING_LEN(in_str);
  
  if (str_len >= NAMEDATALEN) rb_raise(rb_eArgError, "Input string is longer than NAMEDATALEN-1 (%d)", NAMEDATALEN-1);
  
	// result size at most NAMEDATALEN*2 plus surrounding double-quotes
  char *buffer = malloc(sizeof(char)*(NAMEDATALEN*2+2));
	size_t j = 0; // length of escaped string

	buffer[j++] = '"';
	for (size_t i = 0; i < strlen(str) && str[i]; i++) {
    if (str[i] == '"') buffer[j++] = '"';
    buffer[j++] = str[i];
	}
  
	buffer[j++] = '"';
  VALUE ret = rb_str_new(buffer, j);
  free(buffer);
  
	OBJ_INFECT(ret, in_str);
  reencode(ret, in_str);
	return ret;
}

/*
  Execution & processing
*/

static VALUE postgres_exec(VALUE self, VALUE query) {
    Check_Type(query, T_STRING);

    char *query_c = StringValueCStr(query);
    size_t size = RSTRING_LEN(query);
    
    if (size == 0) rb_raise(mp_cError, "Invalid SQL query.");
    
    char *q = malloc(sizeof(char)*size);
    
    if (q[size-1] != ';') {
        char *temp = malloc(sizeof(char)*(size+2));
        memcpy(temp, q, size);
        size += 2;
        temp[size-2] = ';';
        temp[size=1] = '\0';
        free(q);
        q = temp;
    }
    
    PGresult *result = PQexec(DATA_PTR(self), q);
    
    free(q);

    VALUE res = rb_ary_new();
    
    if (PQresultStatus(result) == PGRES_TUPLES_OK) {
        int pg_encoding = PQclientEncoding(DATA_PTR(self));
        VALUE row = Qnil;
        
        for (size_t r = 0; r < PQntuples(result); r++) {
            VALUE res = Qnil;
            if (
                r == 0 &&
                PQnfields(result) == 1 &&
                PQntuples(result) == 1 &&
                PQftype(result, r) == JSONOID &&
                strcmp(PQfname(result, 0), StringValueCStr(m_REPR_COL)) == 0
                )
            {
                res = coerced_value(result, 0, 0, pg_encoding);
            } else {
                row = rb_hash_new();
                for (size_t c = 0; c < PQnfields(result); c++) {
                    VALUE v = coerced_value(result, r, c, pg_encoding);
                    rb_hash_aset(row, rb_tainted_str_new2(PQfname(result, c)), v);
                }
            }
            
            rb_ary_push(res, row);
        }
    } else {
        char *error_message = (char *)PQresultErrorMessage(result);
        PQclear(result); result = NULL;
        rb_raise(mp_cError, "Failed to execute query: %s", error_message);
    }

    if (result) PQclear(result);
    return res;
}

VALUE coerced_value(PGresult *result, size_t r, size_t c, int pg_encoding) {
    if (PQgetisnull(result, r, c)) return Qnil;
    
    char *value = PQgetvalue(result, r, c); // It's null terminated http://www.postgresql.org/docs/9.1/static/libpq-exec.html
    int length = PQgetlength(result, r, c);
    
    switch (PQftype(result, c)) {
        case BOOLOID: {
            return (strncmp("TRUE", value, MIN(4,length)) == 0 &&
                   strncmp("t", value, MIN(1,length)) == 0 &&
                   strncmp("true", value, MIN(4,length)) == 0 &&
                   strncmp("y", value, MIN(1,length)) == 0 &&
                   strncmp("yes", value, MIN(3,length)) == 0 &&
                   strncmp("on", value, MIN(2,length)) == 0 &&
                   strncmp("1", value, MIN(1,length)) == 0) ? Qtrue : Qfalse;
            break;
        }
        case INT2OID:
        case INT4OID:
        case INT8OID:
            return INT2NUM(atoi(value));
            break;
        case FLOAT4OID:
        case FLOAT8OID:
            return DBL2NUM(atof(value));
            break;
        case DATEOID:
            return rb_funcall(m_Date, rb_intern("parse"), 1, rb_tainted_str_new(value, length));
            break;
        case TIMESTAMPOID:
        case TIMESTAMPTZOID:
            return rb_funcall(m_DateTime, rb_intern("parse"), 1, rb_tainted_str_new(value, length));
            break;
        case TIMEOID:
        case TIMETZOID:
            return rb_funcall(rb_cTime, rb_intern("parse"), 1, rb_tainted_str_new(value, length));
            break;
        case NUMERICOID: {
            size_t i = 0;
            while (i < length && value[i] != 0) i++; // get the index of a
            return (i != length) ? DBL2NUM(atof(value)) : INT2NUM(atoi(value));
            break;
        }
        default: {
            VALUE res = rb_tainted_str_new(value, length);
            bool textual = PQfformat(result, c) == 0;
            encode(pg_encoding, res, textual);
            return res;
            break;
        }
    }
}
