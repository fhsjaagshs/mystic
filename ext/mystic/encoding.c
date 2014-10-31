#include "encoding.h"
#include "ruby/st.h"
    
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
static ID s_id_index;

rb_encoding * load_cached_enc(int enc_id) {
    rb_encoding *enc;
    if (!st_lookup(enc_pg2ruby, (st_data_t)enc_id, (st_data_t*)&enc)) return NULL;
    return enc;
}

rb_encoding * cache_enc(rb_encoding *enc, int enc_id) {
    st_insert(enc_pg2ruby, (st_data_t)enc_id, (st_data_t)enc);
    return enc;
}

/*
 * Return the given PostgreSQL encoding ID as an rb_encoding.
 * - returns NULL if the client encoding is 'SQL_ASCII'.
 * - returns ASCII-8BIT if the client encoding is unknown.
 * - :FIXME: remove round tip through loading the encoding
 */
rb_encoding * pg_enc2rb_enc(int enc_id) {
    rb_encoding *enc = load_cached_enc(enc_id);
    if (enc) return enc;
    
    const char *pg_encname = pg_encoding_to_char(enc_id);
    if (strncmp(pg_encname, "SQL_ASCII", 9) == 0) return NULL; // return NULL if the client encoding is 'SQL_ASCII'.
    
    // JOHAB isn't a builtin encoding, so make up a dummy encoding if it's seen
    // find or create JOHAB encoding
    if (strncmp(pg_encname, JOHAB, 5) == 0) {
        int enc_index;
        
        enc_index = rb_enc_find_index(JOHAB);
        
        // Check if JOHAB or an alias of JOHAB exists
        if (enc_index == 0) {
            for (size_t i = 0; i < sizeof(JOHAB_ALIASES)/sizeof(JOHAB_ALIASES[0]); i++) {
                if ((enc_index = rb_enc_find_index(JOHAB_ALIASES[i])) > 0) break;
            }
        }
        
        // create it if it doesn't exist
        if (enc_index == 0) {
            enc_index = rb_define_dummy_encoding(JOHAB);
            for (size_t i = 0; i < sizeof(JOHAB_ALIASES)/sizeof(JOHAB_ALIASES[0]); i++) enc_alias(JOHAB_ALIASES[i], enc_index);
        }
        
        return cache_enc(rb_enc_from_index(enc_index), enc_id);
    } else {
        // Look it up in the conversion table
        size_t enc_map_count = sizeof(pg2ruby_enc_map)/sizeof(pg2ruby_enc_map[0]);
        for (size_t i = 0; i < enc_map_count; ++i) {
            if (strcmp(pg_encname, pg2ruby_enc_map[i][0]) == 0) return cache_enc(rb_enc_find(pg2ruby_enc_map[i][1]), enc_id);
        }
    }
    
    return cache_enc(rb_ascii8bit_encoding(), enc_id); // Fallthrough to ASCII-8BIT
}

// Returns the given rb_encoding as the equivalent PostgreSQL encoding string.
const char * rb_enc2pg_enc(rb_encoding *enc) {
	const char *rb_encname = rb_enc_name(enc);
	const char *encname = NULL;
    size_t enc_map_count = sizeof(pg2ruby_enc_map)/sizeof(pg2ruby_enc_map[0]);
	for (size_t i = 0; i < enc_map_count; ++i) {
		if (strcmp(rb_encname, pg2ruby_enc_map[i][1]) == 0) {
			encname = pg2ruby_enc_map[i][0];
            break;
		}
	}

	if (!encname) encname = SQL_ASCII;
	return encname;
}

void reencode(VALUE reencodee, VALUE reencoder) {
    rb_enc_associate(reencodee, rb_enc_get(reencoder));
}

void encode(int enc_id, VALUE str, bool textual) {
    if (textual) rb_enc_associate_index(str, rb_enc_get_index(pg_enc2rb_enc(enc_id)));
    else rb_enc_associate(str, rb_ascii8bit_encoding());
}
