#include "encoding.h"
#include "postgres_ext.h"

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