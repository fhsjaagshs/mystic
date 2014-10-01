#include <stdio.h>

/* Postgres Headers */
#include "libpq-fe.h"
#include "libpq/libpq-fs.h"
#include "pg_config_manual.h"

/* Ruby headers */
#include "ruby.h"
#include "time.h"

#include "encoding.h"

/* Postgres type oids */
/* Built-in OIDs don't change*/
#define BOOLOID 16
#define INT8OID 20
#define INT2OID 21
#define INT4OID 23
#define JSONOID 114
#define XMLOID 142
#define FLOAT4OID 700
#define FLOAT8OID 701
#define DATEOID 1082
#define TIMEOID 1083
#define TIMESTAMPOID 1114
#define TIMESTAMPTZOID 1184
#define TIMETZOID 1266
#define NUMERICOID 1700

extern VALUE rb_mMystic;
extern VALUE m_cPostgres;
extern VALUE mp_cError;

static void postgres_gc_free(PGconn *conn);
static VALUE postgres_allocate(VALUE klass);

static VALUE postgres_disconnect(VALUE self);
static VALUE postgres_initialize(VALUE self, VALUE hash);
static VALUE postgres_valid(VALUE self);

static VALUE postgres_quote_ident(VALUE self, VALUE in_str);

static VALUE postgres_exec(VALUE self, VALUE query);