/*
  extension.c
  require "mystic/postgres"

  Interface to Postgres for Mystic
  p = Postgres.connect :database => "madeup" # other args too
  res = p.execute "SELECT * FROM table;" # res is an array of hashes, all perfectly coerced and trimmed into Ruby types
  p.disconnect!
*/

#include <iostream>
#include <cstdlib>

#include "postgres.h" // our LibPQ wrapper
#include "postgres_result.h" // out PGresult wrapper
#include "encoding.h" // our postgres encoding to rb_encoding conversion
#include "oids.h" // our postgres OID defines

#include "ruby.h" // ruby header

//#define MIN(a,b) (((a)<(b))?(a):(b))
//#define MAX(a,b) (((a)>(b))?(a):(b))

using namespace std;

extern "C" void Init_postgres();
static void postgres_gc_free(Postgres *conn);
static VALUE postgres_allocate(VALUE klass);
static VALUE postgres_disconnect(VALUE self);
static VALUE postgres_initialize(int argc, VALUE *argv, VALUE self);
static VALUE postgres_valid(VALUE self);
static VALUE postgres_escape_string(VALUE self, VALUE in_str);
static VALUE postgres_escape_literal(VALUE self, VALUE in_str);
static VALUE postgres_escape_identifier(VALUE self, VALUE in_str);
static VALUE postgres_wait_for_notify(VALUE self, VALUE timeout);
static VALUE postgres_exec(VALUE self, VALUE query);

VALUE rb_mMystic = Qnil;
VALUE m_cPostgres = Qnil;
VALUE mp_cError = Qnil;
VALUE m_Date = Qnil;
VALUE m_DateTime = Qnil;

static VALUE coerced_value(PostgresResult &res, size_t r, size_t c, int pg_encoding);

void Init_postgres() {
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
  rb_define_method(m_cPostgres, "wait_for_notify", RUBY_METHOD_FUNC(postgres_wait_for_notify), 1);

  //rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("encoding"));

  if (m_Date == Qnil && m_DateTime == Qnil) {
    // Load Date and DateTime 
    rb_funcall(rb_mKernel, rb_intern("require"), 1, rb_str_new2("date"));
    m_Date = rb_const_get(rb_cObject, rb_intern("Date"));
    m_DateTime = rb_const_get(rb_cObject, rb_intern("DateTime"));
  }
}

static Postgres *getPostgres(VALUE self) {
    Postgres *p;
    Data_Get_Struct(self, Postgres, p);
    return p;
}

static void postgres_gc_free(Postgres *p) {
    if (p) delete p;
    p = NULL;
    ruby_xfree(p);
}

static VALUE postgres_allocate(VALUE klass) {
    return Data_Wrap_Struct(klass, NULL, postgres_gc_free, ruby_xmalloc(sizeof(Postgres)));
}

static VALUE postgres_disconnect(VALUE self) {
    Postgres *p = getPostgres(self);
    if (p) p->disconnect();
    return Qnil;
}

static VALUE postgres_initialize(int argc, VALUE *argv, VALUE self) {
    if (argc == 0 || argc > 2) rb_raise(rb_eArgError, "Invalid number of arguments.");
    
    Postgres *p = getPostgres(self);
    new (p) Postgres();
    
    VALUE rb_keys = Qnil;
    VALUE rb_values = Qnil;
    
    if (argc == 1) {
        Check_Type(argv[0], T_HASH);
        rb_keys = rb_funcall(argv[0], rb_intern("keys"), 0);
        rb_values = rb_funcall(argv[0], rb_intern("values"), 0);
    } else if (argc == 2) {
        Check_Type(argv[0], T_ARRAY);
        Check_Type(argv[1], T_ARRAY);
        rb_keys = argv[0];
        rb_keys = argv[1];
    }
    
    size_t num_pairs = RARRAY_LEN(rb_keys);
    
    char **keys = (char **)malloc(sizeof(char *)*(num_pairs+1));
    char **values = (char **)malloc(sizeof(char *)*(num_pairs+1));
    
    for (size_t i = 0; i < num_pairs; i++) {
     // keys[i] = rb_string_value_cstr(&rb_ary_entry(rb_keys, i));
      VALUE k = rb_funcall(rb_ary_entry(rb_keys, i), rb_intern("to_s"), 0);
      VALUE v = rb_funcall(rb_ary_entry(rb_values, i), rb_intern("to_s"), 0);
      keys[i] = StringValueCStr(k);
      values[i] = StringValueCStr(v);
    }

    keys[num_pairs] = NULL;
    values[num_pairs] = NULL;
    
    try {
        p->connect(keys, values);
    } catch (const char *error_message) {
        free(keys); keys = NULL;
        free(values); values = NULL;
        rb_raise(mp_cError, "%s", error_message);
    }
    
    if (keys) free(keys);
    if (values) free(values);
    
    return Qnil;
}

static VALUE postgres_valid(VALUE self) {
    Postgres *p = getPostgres(self);
    return p->connected() ? Qtrue : Qfalse;
}

static VALUE postgres_escape_string(VALUE self, VALUE in_str) {
    Check_Type(in_str, T_STRING);
    
    Postgres *p = getPostgres(self);

    try {
        string escaped = p->escape_string(string(StringValueCStr(in_str)));
        VALUE rbstr = rb_str_new2(escaped.c_str());
     //   encode(p->client_encoding(), rbstr, true);
        OBJ_INFECT(rbstr, in_str);
        return rbstr;
    } catch (const char *error_message) {
        rb_raise(mp_cError, "%s", error_message);
    }
    
    return Qnil;
}

static VALUE postgres_escape_literal(VALUE self, VALUE in_str) {
    Check_Type(in_str, T_STRING);
    
    Postgres *p = getPostgres(self);
    
    try {
        string escaped = p->escape_literal(string(StringValueCStr(in_str)));
        VALUE rbstr = rb_str_new2(escaped.c_str());
      //  encode(p->client_encoding(), rbstr, true);
        OBJ_INFECT(rbstr, in_str);
        return rbstr;
    } catch (const char *error_message) {
        rb_raise(mp_cError, "%s", error_message);
    }
    
    return Qnil;
}

static VALUE postgres_escape_identifier(VALUE self, VALUE in_str) {
  Check_Type(in_str, T_STRING);

  Postgres *p = getPostgres(self);
  
  try {
      string escaped = p->escape_identifier(string(StringValueCStr(in_str)));
      VALUE rbstr = rb_str_new2(escaped.c_str());
      reencode(rbstr, in_str);
      OBJ_INFECT(rbstr, in_str);
      return rbstr;
  } catch (const char *error_message) {
      rb_raise(mp_cError, "%s", error_message);
  }
  
  return Qnil;
}

static VALUE postgres_wait_for_notify(VALUE self, VALUE timeout) {
    Postgres *p = getPostgres(self);
    
    map<const char *, string> values;
    
    try {
        values = p->wait_for_notify(NUM2DBL(timeout));
    } catch (char *error_message) {
        rb_raise(mp_cError, "%s", error_message);
    } catch (int fatal_code) {
        if (fatal_code < 0) rb_sys_fail("Fatal error waiting for socket.");
    }
    
    VALUE relname = rb_tainted_str_new2(values["relname"].c_str());
    // encode(p->client_encoding(), relname, true);
    VALUE be_pid = INT2NUM(atoi(values["be_pid"].c_str()));
    VALUE extra = rb_tainted_str_new2(values["extra"].c_str());
    // encode(p->client_encoding(), extra, true);
    
    if (rb_block_given_p()) rb_yield_values(3, relname, be_pid, extra);
    
    return Qnil;
}

static VALUE postgres_exec(VALUE self, VALUE query) {
  Check_Type(query, T_STRING);

  Postgres *p = getPostgres(self);
  
  try {
    VALUE config = rb_funcall(rb_mMystic, rb_intern("config"), 0);
    VALUE rb_json_col = rb_funcall(config, rb_intern("json_column"), 0);
      
    PostgresResult res(p->execute(string(StringValueCStr(query))));
    res.json_col = StringValueCStr(rb_json_col);
    
    if (res.json()) {
      return rb_tainted_str_new2(res.at(0,0).c_str());
    } else {
      VALUE rows = rb_ary_new();
      for (size_t r = 0; r < res.number_rows(); r++) {
        VALUE row = rb_hash_new();
        for (size_t c = 0; c < res.number_cols(); c++) {
          VALUE k = rb_tainted_str_new2(res.col_name(c).c_str());
          VALUE v = coerced_value(res, r, c, p->client_encoding());
          rb_hash_aset(row, k, v);
        }
        rb_ary_push(rows, row);
      }
      return rows;
    }
  } catch (char *error_message) {
    rb_raise(mp_cError, "%s", error_message);
  }
  
  return Qnil;
}

static VALUE coerced_value(PostgresResult &res, size_t r, size_t c, int pg_encoding) {
  if (res.null_at(r,c)) return Qnil;

  string v = res.at(r, c);
  
  switch (res.col_oid(c)) {
  case BOOLOID: {
    return (v == "TRUE" || v == "t" || v == "true" || v == "y" || v == "yes" || v == "on" || v == "1") ? Qtrue : Qfalse;
    break;
  }
  case MONEYOID:
    return DBL2NUM(atof(v.c_str()+1)); // first character is a dollar sign
    break;
  case INT2OID:
  case INT4OID:
  case INT8OID:
  case OIDOID:
    return INT2NUM(atoi(v.c_str()));
    break;
  case FLOAT4OID:
  case FLOAT8OID:
    return DBL2NUM(atof(v.c_str()));
    break;
  case DATEOID:
    return rb_funcall(m_Date, rb_intern("parse"), 1, rb_tainted_str_new2(v.c_str()));
    break;
  case TIMESTAMPOID:
  case TIMESTAMPTZOID:
    return rb_funcall(m_DateTime, rb_intern("parse"), 1, rb_tainted_str_new2(v.c_str()));
    break;
  case TIMEOID:
  case TIMETZOID:
    return rb_funcall(rb_cTime, rb_intern("parse"), 1, rb_tainted_str_new2(v.c_str()));
    break;
  case NUMERICOID: {
    size_t i = 0;
    while (i < v.length() && v[i] != '.') i++; // get the index of a
    return (i != v.length()) ? DBL2NUM(atof(v.c_str())) : INT2NUM(atoi(v.c_str()));
    break;
  }
  default: {
    VALUE str = rb_tainted_str_new2(v.c_str());
    encode(pg_encoding, str, !res.col_binary(c));
    return str;
    break;
  }
  }
}
