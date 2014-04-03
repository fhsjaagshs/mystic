#include "string_c_ext.h"
#include "ruby.h"

static VALUE minify(VALUE mod);

void Init_string_c_ext() {
    rb_define_method(rb_cString, "minify", RUBY_METHOD_FUNC(minify), 0);
}

static VALUE minify(VALUE self) {
    // Convert ruby string into c string and length
    int length = RSTRING_LEN(self);
    char *string = RSTRING_PTR(self);
    
    // set up string to accept characters from ruby string
    char sanitized[length+1];
    int sanitized_index = 0; // since the overall length of the original string > length of the minified string
    
    int is_in_quotes = 0;
    int is_in_spaces = 0;
    
    for (int i = 0; i < length; i++) {
        char curr_char = string[i];
        
        // current char is a quote
        if (curr_char == '"' || curr_char == '\'') {
            is_in_quotes = (is_in_quotes == 0)?1:0;
        }
        
        // if in quotes, add the character automatically
        if (is_in_quotes == 1) {
            sanitized[sanitized_index] = curr_char;
            sanitized_index++;
            continue;
        }
        
        switch (curr_char) {
            case '\n':
                // skip
                // just ignore this character
                break;
            case '\t':
                curr_char = ' ';
                break;
            case ' ':
                // If this is the first space, add the space
                if (is_in_spaces == 0) {
                    sanitized[sanitized_index] = curr_char;
                    sanitized_index++;
                }
                
                // indicate that we are in a series of spaces
                is_in_spaces = 1;
                break;
            default: // this is every other character
                is_in_spaces = 0;
                sanitized[sanitized_index] = curr_char;
                sanitized_index++;
                break;
        }
    }
    sanitized[sanitized_index] = '\0'; // don't add anything to the index because it will have been incremented after the last character is appended in the for loop
    return rb_str_new2(sanitized);
}