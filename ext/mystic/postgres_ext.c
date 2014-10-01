/*
  postgres.c
  require "mystic/postgres"

  Interface to Postgres for Mystic
  p = Postgres.connect :database => "madeup" # other args too
  res = p.execute "SELECT * FROM table;" # res is an array of hashes, all perfectly coerced and trimmed into Ruby types
  p.disconnect!

*/

#include "postgres_ext.h"

VALUE rb_mMystic = Qnil;
VALUE m_cPostgres = Qnil;
VALUE mp_cError = Qnil;

void Init_postgres_ext() {
    rb_mMystic = rb_define_module("Mystic");
    m_cPostgres = rb_define_class_under(rb_mMystic, "Postgres", rb_cObject);
    mp_cError = rb_define_class_under(m_cPostgres, "Error", rb_eStandardError);
    rb_define_alloc_func(m_cPostgres, postgres_allocate);
    rb_define_method(m_cPostgres, "initialize", RUBY_METHOD_FUNC(postgres_initialize), -2);
    rb_define_method(m_cPostgres, "execute", RUBY_METHOD_FUNC(postgres_exec), 1);
    rb_define_method(m_cPostgres, "valid?", RUBY_METHOD_FUNC(postgres_valid), 0);
    rb_define_method(m_cPostgres, "quote_ident", RUBY_METHOD_FUNC(postgres_quote_ident), 1);
    rb_define_method(m_cPostgres, "disconnect!", RUBY_METHOD_FUNC(postgres_disconnect), 0);
    rb_define_singleton_method(m_cPostgres, "quote_ident", RUBY_METHOD_FUNC(postgres_quote_ident), 1);
}

//
// Helpers
//

void inspect(VALUE obj) {
  printf("Before inspect...\n");
  printf("%s\n",RSTRING_PTR(rb_funcall(obj, rb_intern("inspect"), 0)));
  printf("After inspect...\n");
}

// TODO:
// - 2 more escape methods
// Encodings

// GC Free
static void postgres_gc_free(PGconn *conn) {
  if (conn != NULL) PQfinish(conn);
}

static VALUE postgres_allocate(VALUE klass) {
	VALUE self = Data_Wrap_Struct(klass, NULL, postgres_gc_free, NULL);
	rb_iv_set(self, "@special_field", Qnil);
  rb_iv_set(self, "@options", Qnil);
  rb_iv_set(self, "@error", Qnil);
	return self;
}

// Returns the PGconn pointer in use
PGconn * get_conn(VALUE self) {
  return DATA_PTR(self);
}

void destroy_conn(VALUE self) {
  PQfinish(get_conn(self));
  DATA_PTR(self) = NULL;
}

/*
  Connections
*/

static VALUE postgres_disconnect(VALUE self) {
  destroy_conn(self);
  return Qnil;
}

static VALUE postgres_initialize(VALUE self, VALUE args) {
  if (RARRAY_LEN(args) != 1) {
    rb_raise(rb_eArgError, "Invalid arguments.");
    return Qnil;
  }
  
  VALUE hash = rb_ary_entry(args, 0); // the connection options
  Check_Type(hash, T_HASH);
  
  VALUE connstr = rb_funcall(self, rb_intern("connstr"), 1, hash);
  
  PGconn *conn = NULL;
  conn = PQconnectdb(StringValueCStr(connstr));
  
  if (conn == NULL) {
    rb_raise(mp_cError, "Failed to create a connection.");
    return Qnil;
  }
  
  if (PQstatus(conn) == CONNECTION_BAD) {
    VALUE error = rb_exc_new2(mp_cError, PQerrorMessage(conn));
    rb_iv_set(self, "@error", error);
    rb_exc_raise(error);
  }
  
  Check_Type(self, T_DATA);
  DATA_PTR(self) = conn;
  rb_iv_set(self, "@options", hash);
  return self;
}

static VALUE postgres_valid(VALUE self) {
  return (get_conn(self) != NULL && PQstatus(get_conn(self)) == CONNECTION_OK) ? Qtrue : Qfalse;
}

/*
  Escaping
*/

static VALUE postgres_quote_ident(VALUE self, VALUE in_str) {
	VALUE ret;
	char *str = RSTRING_PTR(in_str);
  size_t str_len = RSTRING_LEN(in_str);
  
  if (str_len >= NAMEDATALEN) rb_raise(rb_eArgError, "Input string is longer than NAMEDATALEN-1 (%d)", NAMEDATALEN-1);
  
	/* result size at most NAMEDATALEN*2 plus surrounding
	 * double-quotes. */
	char buffer[NAMEDATALEN*2+2];
	size_t i = 0, j = 0;

	buffer[j++] = '"';
	for (i = 0; i < strlen(str) && str[i]; i++) {
    if (str[i] == '"') buffer[j++] = '"';
    buffer[j++] = str[i];
	}
  
	buffer[j++] = '"';
	ret = rb_str_new(buffer,j);
	OBJ_INFECT(ret, in_str);
  
  //encode_if_possible(self,ret);

	return ret;
}

/*
  Execution & processing
*/

static VALUE postgres_exec(VALUE self, VALUE query) {
  PGresult *result = PQexec(get_conn(self), StringValueCStr(query));
  size_t num_rows = PQntuples(result);
  size_t num_cols = PQnfields(result);
  
  if (num_rows == 0) return rb_ary_new();
  
  // Catch JSON and XML returned from Mystic
  if (num_rows == 1 && num_cols == 1) {
    unsigned oid = PQftype(result, 0);
    if (oid == XMLOID || oid == JSONOID) {
      VALUE col_name = rb_iv_get(self, "@special_field");
      if (RSTRING_LEN(col_name) == 0 || strcmp(PQfname(result, 0), StringValueCStr(col_name)) == 0) {
        char *value = PQgetvalue(result, 0, 0);
        int length = PQgetlength(result, 0, 0);
        VALUE res = rb_str_new(value, length);
        encode_if_possible(self, res);
        return res;
      }
    }
  }
  
  VALUE rows = rb_ary_new2(num_rows);
  VALUE names = rb_ary_new2(num_cols);
  
  for (size_t c = 0; c < num_cols; c++) {
    rb_ary_push(names, rb_str_new2(PQfname(result, c)));
  }
  
  VALUE Date = rb_const_get(rb_cObject, rb_intern("Date"));
  rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("date"));
  VALUE DateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));
  ID parse = rb_intern("parse");
  
  // Coerce the parameter
  for (size_t r = 0; r < num_cols; r++) {
    VALUE row = rb_hash_new();
    
    for (size_t c = 0; c < num_cols; c++) {
      VALUE key = rb_ary_entry(names, c);
      if (PQgetisnull(result, r, c)) {
        rb_hash_aset(row, key, Qnil);
      } else {
        char *value = PQgetvalue(result, r, c); // It's null terminated http://www.postgresql.org/docs/9.1/static/libpq-exec.html
        int length = PQgetlength(result, r, c);
    
        VALUE res;

        switch (PQftype(result, c)) {
          case BOOLOID: {
            if (strcmp("TRUE", value) == 0 &&
                strcmp("t", value) == 0 &&
                strcmp("true", value) == 0 &&
                strcmp("y", value) == 0 &&
                strcmp("yes", value) == 0 &&
                strcmp("on", value) == 0 &&
                strcmp("1", value) == 0) {
              res = Qtrue;
            } else {
              res = Qfalse;
            }
            break;
          }
          case INT2OID:
          case INT4OID:
          case INT8OID:
            res = INT2NUM(atoi(value));
            break;
          case FLOAT4OID:
          case FLOAT8OID:
            res = DBL2NUM(atof(value));
            break;
          case DATEOID:
            res = rb_funcall(Date, parse, 1, rb_str_new(value, length));
            break;
          case TIMESTAMPOID:
          case TIMESTAMPTZOID:
            res = rb_funcall(DateTime, parse, 1, rb_str_new(value, length));
            break;
          case TIMEOID:
          case TIMETZOID:
            res = rb_funcall(rb_cTime, parse, 1, rb_str_new(value, length));
            break;
          case NUMERICOID: {
            size_t i = 0;
            while (i < length && value[i] != 0) i++; // get the index of a 
        
            if (i != length) { // there's a dot, so it's a float
              res = DBL2NUM(atof(value));
            } else {
              res = INT2NUM(atoi(value));
            }
        
            break;
          }
          default:
            res = rb_str_new(value, length);
            break;
        }
        
      //  encode_if_possible(self, res);
        
        rb_hash_aset(row, key, res);
        printf("Name: %s, OID: %u\n",StringValueCStr(key),PQftype(result, c));
        
       /* INT2ARRAYOID   1005
        #define 	INT4ARRAYOID   1007
        #define 	TEXTARRAYOID   1009
        #define 	OIDARRAYOID   1028
        #define 	FLOAT4ARRAYOID   1021*/
        
        // TODO: Implement
        // DateTime - TIMESTAMPOID, TIMESTAMPTZOID
        // Time - TIMETZOID, TIMEOID
        // Date - DATEOID
        // ??? special class or numeric/float/integer - INTERVALOID, TINTERVALOID
      }
    }
    rb_ary_push(rows,row);
  }
  
  return rows;
}