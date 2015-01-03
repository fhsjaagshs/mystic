#include "ruby.h"
#include <stdbool.h>

#ifdef __cplusplus
// "__cplusplus" is defined whenever it's a C++ compiler,
// not a C compiler, that is doing the compiling.
extern "C" {
#endif

void reencode(VALUE reencodee, VALUE reencoder);
void encode(int enc_id, VALUE str, bool textual);

#ifdef __cplusplus
}
#endif