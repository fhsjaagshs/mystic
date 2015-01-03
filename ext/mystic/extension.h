#include <stdio.h>

/* Postgres Headers */
#include "libpq-fe.h"
#include "pg_config_manual.h" // for NAMEDATALEN

/* Ruby headers */
#include "ruby.h"
#include "time.h"

/* Internal headers */
#include "encoding.h"

/* Postgres type oids */
/* Built-in OIDs don't change*/
#define BOOLOID 16

#define INT8OID 20
#define INT2OID 21
#define INT4OID 23
#define FLOAT4OID 700
#define FLOAT8OID 701
#define NUMERICOID 1700
#define OIDOID 26

#define MONEYOID 790

// Representation formats
#define JSONOID 114
#define XMLOID 142

// Date/Time formats
#define ABSTIMEOID 702
#define DATEOID 1082
#define TIMEOID 1083
#define TIMESTAMPOID 1114
#define TIMESTAMPTZOID 1184
#define TIMETZOID 1266

// IMPORTANT!
// To get the types, use the below query:
// SELECT typname, oid, typtype FROM pg_type WHERE typtype = 'b';
// this is a good link: http://www.postgresql.org/docs/current/interactive/catalog-pg-type.html

extern VALUE rb_mMystic;
extern VALUE m_cPostgres;
extern VALUE mp_cError;
extern VALUE m_Date;
extern VALUE m_DateTime;
extern VALUE m_REPR_COL;

VALUE process_row(PGresult *result, char *name, size_t r);

extern "C" void Init_postgres();

static void postgres_gc_free(PGconn *conn);
static VALUE postgres_allocate(VALUE klass);
static VALUE postgres_disconnect(VALUE self);
static VALUE postgres_initialize(int argc, VALUE *argv, VALUE self);
static VALUE postgres_valid(VALUE self);
static VALUE postgres_escape_string(VALUE self, VALUE in_str);
static VALUE postgres_escape_literal(VALUE self, VALUE in_str);
static VALUE postgres_escape_identifier(VALUE self, VALUE in_str);
static VALUE postgres_exec(VALUE self, VALUE query);