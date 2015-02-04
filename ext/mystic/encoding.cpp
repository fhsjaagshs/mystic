#include "encoding.h"
#include "ruby/st.h"
#include "ruby/encoding.h"
#include "libpq-fe.h"

int rb_encdb_alias(const char *alias, const char *orig);
//extern int enc_alias(const char *, int); // Function is in encoding.c, so we have to define it here to use it.

// The map from canonical encoding names in PostgreSQL to ones in Ruby.
const char * const (pg2ruby_enc_map[][2]) = {
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
    // {"JOHAB",         "JOHAB"       }, // dummy
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
    // {"SQL_ASCII",     NULL          }, // special case
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

static const char * const SQL_ASCII = "SQL_ASCII";
static const char * const JOHAB = "JOHAB";
static const char * const JOHAB_ALIASES[] = { "Windows-1361", "CP1361" };

static struct st_table *enc_pg2ruby;

static size_t pg2ruby_enc_map_count = sizeof(pg2ruby_enc_map)/sizeof(pg2ruby_enc_map[0]);
size_t johab_aliases_count = sizeof(JOHAB_ALIASES)/sizeof(JOHAB_ALIASES[0]);

rb_encoding * load_cached_enc(int enc_id) {
    rb_encoding *enc;
    if (!st_lookup(enc_pg2ruby, (st_data_t)enc_id, (st_data_t *)&enc)) return NULL;
    return enc;
}

void cache_enc(rb_encoding *enc, int enc_id) {
    st_insert(enc_pg2ruby, (st_data_t)enc_id, (st_data_t)enc);
}

/*
 * Return the given PostgreSQL encoding ID as an rb_encoding.
 * - returns NULL if the client encoding is 'SQL_ASCII'.
 * - returns ASCII-8BIT if the client encoding is unknown.
 */
rb_encoding * pg_enc2rb_enc(int enc_id) {
  printf("pg_enc2rb_enc()");
    rb_encoding *enc = load_cached_enc(enc_id);
    if (enc) return enc;
    
    const char *pg_encname = pg_encoding_to_char(enc_id);
    
    printf("Encoding: %s\n",pg_encname);
    
    if (strcmp(pg_encname, "SQL_ASCII") == 0) return NULL; // SQL_ASCII denotes ignorance of encoding.
    
    rb_encoding *encoding = rb_ascii8bit_encoding(); // default to ASCII-8BIT
    
    if (strcmp(pg_encname, "JOHAB") == 0) { // JOHAB isn't a builtin encoding, so make up a dummy encoding if it's seen
        // check if JOHAB exists
        int enc_index = rb_enc_find_index(JOHAB);
        
        // check if one of its aliases exists if it doesn't exist
        if (enc_index == 0) {
            for (size_t i = 0; i < johab_aliases_count; i++) {
                if ((enc_index = rb_enc_find_index(JOHAB_ALIASES[i])) > 0) break;
            }
        }
        
        // create it if it doesn't exist
        if (enc_index == 0) {
            enc_index = rb_define_dummy_encoding(JOHAB);
            for (size_t i = 0; i < johab_aliases_count; i++) rb_encdb_alias(JOHAB_ALIASES[i], JOHAB); //enc_alias(JOHAB_ALIASES[i], enc_index);
        }
        
        encoding = rb_enc_from_index(enc_index);
    } else {
        // Look it up in the conversion table
        for (size_t i = 0; i < pg2ruby_enc_map_count; i++) {
            if (strcmp(pg_encname, pg2ruby_enc_map[i][0]) == 0) {
              encoding = rb_enc_find(pg2ruby_enc_map[i][1]);
              break;
            }
        }
    }
    
    cache_enc(encoding, enc_id);
    return encoding;
}

void reencode(VALUE reencodee, VALUE reencoder) {
    rb_enc_associate(reencodee, rb_enc_get(reencoder));
}

void encode(int enc_id, VALUE str, bool textual) {
    if (textual) {
      
      rb_encoding *enc = pg_enc2rb_enc(enc_id);
      if (enc) rb_enc_associate(str, enc);
    }
    else rb_enc_associate(str, rb_ascii8bit_encoding());
}
