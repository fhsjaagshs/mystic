require "mkmf"

with_cflags("-I/usr/local/include") { true }
with_ldflags("-L/usr/local/lib -lpq") { true }

create_makefile "mystic/postgres_ext"