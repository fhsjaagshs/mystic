#include <stdio.h>

/* Postgres Headers */
#include "libpq-fe.h"
#include "libpq/libpq-fs.h"
#include "pg_config_manual.h"

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
#define NUMERICOID 1700

/* Ruby headers */
#include "ruby.h"
#ifdef HAVE_RUBY_ST_H
#	include "ruby/st.h"
#elif HAVE_ST_H
#	include "st.h"
#endif

#if defined(HAVE_RUBY_ENCODING_H) && HAVE_RUBY_ENCODING_H
#	include "ruby/encoding.h"
#	define ENCODING_SUPPORTED
#	define ASSOCIATE_INDEX( obj, index_holder ) rb_enc_associate_index((obj), pg_enc_get_index((index_holder)))
#	ifdef HAVE_RB_ENCDB_ALIAS
		extern int rb_encdb_alias(const char *, const char *);
#		define ENC_ALIAS(name, orig) rb_encdb_alias((name), (orig))
#	elif HAVE_RB_ENC_ALIAS
		extern int rb_enc_alias(const char *, const char *);
#		define ENC_ALIAS(name, orig) rb_enc_alias((name), (orig))
#	else
		extern int rb_enc_alias(const char *alias, const char *orig); /* declaration missing in Ruby 1.9.1 */
#		define ENC_ALIAS(name, orig) rb_enc_alias((name), (orig))
#	endif
#else
#	define ASSOCIATE_INDEX( obj, index_holder ) /* nothing */
#endif

#ifdef ENCODING_SUPPORTED
/**
 * The mapping from canonical encoding names in PostgreSQL to ones in Ruby.
 */
const char * const (pg_enc_pg2ruby_mapping[][2]) = {
	{"BIG5",          "Big5"        },
	{"EUC_CN",        "GB2312"      },
	{"EUC_JP",        "EUC-JP"      },
	{"EUC_JIS_2004",  "EUC-JP"      },
	{"EUC_KR",        "EUC-KR"      },
	{"EUC_TW",        "EUC-TW"      },
	{"GB18030",       "GB18030"     },
	{"GBK",           "GBK"         },
	{"ISO_8859_5",    "ISO-8859-5"  },
	{"ISO_8859_6",    "ISO-8859-6"  },
	{"ISO_8859_7",    "ISO-8859-7"  },
	{"ISO_8859_8",    "ISO-8859-8"  },
	/* {"JOHAB",         "JOHAB"       }, dummy */
	{"KOI8",          "KOI8-R"      },
	{"KOI8R",         "KOI8-R"      },
	{"KOI8U",         "KOI8-U"      },
	{"LATIN1",        "ISO-8859-1"  },
	{"LATIN2",        "ISO-8859-2"  },
	{"LATIN3",        "ISO-8859-3"  },
	{"LATIN4",        "ISO-8859-4"  },
	{"LATIN5",        "ISO-8859-9"  },
	{"LATIN6",        "ISO-8859-10" },
	{"LATIN7",        "ISO-8859-13" },
	{"LATIN8",        "ISO-8859-14" },
	{"LATIN9",        "ISO-8859-15" },
	{"LATIN10",       "ISO-8859-16" },
	{"MULE_INTERNAL", "Emacs-Mule"  },
	{"SJIS",          "Windows-31J" },
	{"SHIFT_JIS_2004","Windows-31J" },
	/* {"SQL_ASCII",     NULL          },  special case*/
	{"UHC",           "CP949"       },
	{"UTF8",          "UTF-8"       },
	{"WIN866",        "IBM866"      },
	{"WIN874",        "Windows-874" },
	{"WIN1250",       "Windows-1250"},
	{"WIN1251",       "Windows-1251"},
	{"WIN1252",       "Windows-1252"},
	{"WIN1253",       "Windows-1253"},
	{"WIN1254",       "Windows-1254"},
	{"WIN1255",       "Windows-1255"},
	{"WIN1256",       "Windows-1256"},
	{"WIN1257",       "Windows-1257"},
	{"WIN1258",       "Windows-1258"}
};

static struct st_table *enc_pg2ruby;
static ID s_id_index;

#endif

static const char * const postgres_fields[10] = {
  "host", "hostaddr", "port", "dbname", "user", "password", "connect_timeout", "client_encoding", "options", "sslmode"
};

static VALUE postgres_disconnect(VALUE self);
static VALUE postgres_initialize(VALUE self, VALUE hash);
static VALUE class_postgres_connect(VALUE klass, VALUE hash);
static VALUE postgres_valid(VALUE self);

static VALUE postgres_quote_ident(VALUE self, VALUE in_str);

static VALUE postgres_exec(VALUE self, VALUE query);