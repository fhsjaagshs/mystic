require "mkmf"

with_cflags("-I/usr/local/pgsql/include") { true }

create_makefile "mystic/postgres"