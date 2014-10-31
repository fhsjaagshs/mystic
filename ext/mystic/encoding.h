#include "ruby.h"
#include <stdbool.h>
#include "ruby/encoding.h"

void reencode(VALUE reencodee, VALUE reencoder);
void encode(int enc_id, VALUE str, bool textual);