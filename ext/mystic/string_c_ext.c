#include "string_c_ext.h"
#include "ruby.h"

// "this is a "string   this" with      many spaces"
// becomes
// "this is a "string   this" with many spaces"

static VALUE minify(VALUE mod);

void Init_string_c_ext() {
    rb_define_method(rb_cString, "minify", RUBY_METHOD_FUNC(minify), 0);
}

static VALUE minify(VALUE self) {
    int length = RSTRING_LEN(self);
    char *string = RSTRING_PTR(self);
    
    char sanitized[length+1];
    int sanitized_index = 0;
    
    int is_in_quotes = 0;
    int is_in_spaces = 0;
    int is_in_escape_sequence = 0;
    
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
        
        if (curr_char == '\n') {
            continue;
        } else if (curr_char == '\t') {
            curr_char = ' ';
        }

        // current char is a space, outside of any quotes
        if (curr_char == ' ') {
            // indicate that we are in a series of spaces
            
            // If this is the first space, add the space
            if (is_in_spaces == 0) {
                sanitized[sanitized_index] = curr_char;
                sanitized_index++;
            }
            
            is_in_spaces = 1;
        } else {
            is_in_spaces = 0;
            sanitized[sanitized_index] = curr_char;
            sanitized_index++;
        }
    }
    sanitized[sanitized_index] = '\0'; // don't add anything to the index because it will have been incremented after the last character is appended in the for loop
    return rb_str_new2(sanitized);
}