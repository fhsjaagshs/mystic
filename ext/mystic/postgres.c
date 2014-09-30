/*
  postgres.c
  require "mystic/postgres"

  Interface to Postgres for Mystic
  p = Postgres.connect :database => "madeup" # other args too
  res = p.execute "SELECT * FROM table;" # res is an array of hashes, all perfectly coerced and trimmed into Ruby types
  p.disconnect!

*/

#include "postgres.h"

VALUE rb_mMystic = Qnil;
VALUE m_cPostgres = Qnil;
VALUE mp_cError = Qnil;

void Init_postgres() {
    rb_mMystic = rb_define_module("Mystic");
    m_cPostgres = rb_define_class_under(rb_mMystic, "Postgres", rb_cObject);
    mp_cError = rb_define_class_under(m_cPostgres, "Error", rb_eStandardError);
    rb_define_method(m_cPostgres, "initialize", RUBY_METHOD_FUNC(postgres_exec), -2);
    rb_define_method(m_cPostgres, "execute", RUBY_METHOD_FUNC(postgres_exec), 1);
    rb_define_method(m_cPostgres, "valid?", RUBY_METHOD_FUNC(postgres_valid), 0);
    rb_define_method(m_cPostgres, "quote_ident", RUBY_METHOD_FUNC(postgres_quote_ident), 1);
    rb_define_method(m_cPostgres, "disconnect!", RUBY_METHOD_FUNC(postgres_disconnect), 0);
    rb_define_singleton_method(m_cPostgres, "quote_ident", RUBY_METHOD_FUNC(postgres_quote_ident), 1);
    rb_define_singleton_method(m_cPostgres, "connect", RUBY_METHOD_FUNC(class_postgres_connect), -2);
}

// TODO:
// - 2 more escape methods

// GC Free
static void postgres_gc_free(PGconn *conn) {
  if (conn != NULL) PQfinish(conn);
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

char * make_conn_string(VALUE hash) {
  VALUE ret = rb_str_new2("");
  
  size_t num_pgconn_fields = sizeof(postgres_fields)/sizeof(postgres_fields[0]);
  VALUE keys = rb_funcall(hash, rb_intern("keys"), 0);
  VALUE values = rb_funcall(hash, rb_intern("values"), 0);
  VALUE space = rb_str_new2(" ");
  VALUE equals = rb_str_new2("=");
  VALUE singleq = rb_str_new2("'");
  
  VALUE gsub_match = rb_str_new2("");
  
  size_t hash_size = (size_t)NUM2INT(RARRAY_LEN(keys));
  
  for (size_t i = 0; i < hash_size; i++) {
    int valid = 0;
    VALUE rb_key = rb_ary_entry(keys, i);
    VALUE rb_value = rb_ary_entry(values, i);
    // escaping
    rb_funcall(rb_value, rb_intern("gsub!"), 2, rb_str_new2("\\"), rb_str_new2("\\\\\\"));
    rb_funcall(rb_value, rb_intern("gsub!"), 2, rb_str_new2("'"), rb_str_new2("\\\\'"));
    char *key = StringValueCStr(rb_key);
    for (size_t j; j < num_pgconn_fields; j++) {
      if (key == postgres_fields[j]) {
        valid = 1;
        break;
      } else {
        valid = 0;
      }
    }
    
    if (valid == 1) {
      ret = rb_funcall(ret, rb_intern("+"), 1, rb_key);
      ret = rb_funcall(ret, rb_intern("+"), 1, equals);
      ret = rb_funcall(ret, rb_intern("+"), 1, singleq);
      ret = rb_funcall(ret, rb_intern("+"), 1, rb_value);
      ret = rb_funcall(ret, rb_intern("+"), 1, singleq);
      
      if (i < hash_size-1) {
        ret = rb_funcall(ret, rb_intern("+"), 1, space);
      }
    }
  }

  return StringValueCStr(ret);
}

static VALUE postgres_initialize(VALUE self, VALUE args) {
  if (RARRAY_LEN(args) != 1) rb_raise(rb_eArgError, "No arguments."); return Qnil;
  
  VALUE hash = rb_ary_entry(args, 0); // the connection options
  //Check_Type(hash, T_HASH);
  
  // connect
  PGconn *conn = NULL;
  conn = PQconnectdb(make_conn_string(hash));
  
  if (conn == NULL) {
    rb_raise(mp_cError, "Failed to create a connection.");
    return Qnil;
  }
  
  Check_Type(self, T_DATA);
  DATA_PTR(self) = conn;
  rb_iv_set(hash, "@options", self);
  return self;
}

static VALUE class_postgres_connect(VALUE klass, VALUE args) {
  return rb_funcall(klass, rb_intern("new"), 1, args);
}

static VALUE postgres_valid(VALUE self) {
  return get_conn(self) != NULL && PQstatus(get_conn(self)) == CONNECTION_OK;
}

/*
  Escaping
*/

void encode_if_possible(VALUE self, VALUE str) {
#ifdef ENCODING_SUPPORTED
  rb_encoding *enc = NULL;
  
	if (rb_obj_class(self) == m_cPostgres) {
    int enc_id = PQclientEncoding(DATA_PTR(self));
    rb_encoding *temp;

    /* Use the cached value if it exists */
    if (st_lookup(enc_pg2ruby, (st_data_t)enc_id, (st_data_t *)&temp) ) {
      enc = temp;
    } else {
      const char *pg_encname = pg_encoding_to_char(enc_id);

      /* Trying looking it up in the conversion table */
      for (size_t i = 0; i < sizeof(pg_enc_pg2ruby_mapping)/sizeof(pg_enc_pg2ruby_mapping[0]); ++i ) {
        if (strcmp(pg_encname, pg_enc_pg2ruby_mapping[i][0]) == 0) {
          enc = rb_enc_find(pg_enc_pg2ruby_mapping[i][1]);
        }
      }
      
      if (enc == NULL) {
        /* JOHAB isn't a builtin encoding, so make up a dummy encoding if it's seen */
        if (strncmp(pg_encname, "JOHAB", 5) == 0) {
          static const char * const aliases[] = { "JOHAB", "Windows-1361", "CP1361" };
          int enc_index;
          size_t i;

          for (i = 0; i < sizeof(aliases)/sizeof(aliases[0]); ++i) {
          	enc_index = rb_enc_find_index(aliases[i]);
            if (enc_index > 0) enc = rb_enc_from_index(enc_index); break;
          }
          
          if (enc == NULL) {
            enc_index = rb_define_dummy_encoding(aliases[0]);
            for (i = 1; i < sizeof(aliases)/sizeof(aliases[0]); ++i) ENC_ALIAS(aliases[i], aliases[0]);
        
            enc = rb_enc_from_index(enc_index);
          }
        } else {
          enc = rb_ascii8bit_encoding();
        }

        st_insert(enc_pg2ruby, (st_data_t)enc_id, (st_data_t)enc);
      }
    }
	} else {
		enc = rb_enc_get(str);
	}
  
	rb_enc_associate(str, enc);
#endif
}

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
  
  encode_if_possible(self,ret);

	return ret;
}

/*
  Execution & processing
*/

static VALUE postgres_exec(VALUE self, VALUE query) {
  PGresult *result = PQexec(get_conn(self), StringValueCStr(query));
  size_t num_rows = PQntuples(result);
  size_t num_cols = PQnfields(result);
  
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
  
  // Normal rows
  
  VALUE rows = rb_ary_new2(num_rows);
  
  if (num_rows == 0) return rows; // No rows
  
  // Load the names once
  VALUE names = rb_ary_new2(num_cols);
  
  for (size_t c = 0; c < num_cols; c++) {
    rb_ary_push(names, rb_str_new2(PQfname(result, c)));
  }
  
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
            res = rb_funcall(rb_mKernel, rb_intern("Integer"), 1, rb_str_new(value, length));
            break;
          case FLOAT4OID:
          case FLOAT8OID:
            res = rb_funcall(rb_mKernel, rb_intern("Float"), 1, rb_str_new(value, length));
            break;
          case NUMERICOID: {
            size_t i = 0;
            while (i < length && value[i] != 0) i++; // get the index of a 
        
            if (i != length) { // there's a dot, so it's a float
              res = rb_funcall(rb_mKernel, rb_intern("Float"), 1, rb_str_new(value, length));
            } else {
              res = rb_funcall(rb_mKernel, rb_intern("Integer"), 1, rb_str_new(value, length));
            }
        
            break;
          }
          default:
            res = rb_str_new(value, length);
            break;
        }
        
        encode_if_possible(self, res);
        
        rb_hash_aset(row, key, res);
    
        // TODO: Implement
        // DateTime - TIMESTAMPOID, TIMESTAMPTZOID
        // Time - TIMETZOID, TIMEOID
        // Date - DATEOID, ABSTIMEOID, RELTIMEOID
        // ??? special class or numeric/float/integer - INTERVALOID, TINTERVALOID
      }
    }
    rb_ary_push(rows,row);
  }
  
  return rows;
}