require "mkmf"

$libs += "-lstdc++"

with_cflags("-I/usr/local/include -std=c99") { true }
with_cppflags("-I/usr/local/include -std=c++0x") { true }
with_ldflags("-L/usr/local/lib -lpq") { true }

pg_config_path = with_config("pg-config") || with_config("pg_config")

unless enable_config("windows-cross")
  checking_for checking_message("pg_config", nil) do
    pg_config_path = find_executable0("pg_config") || `find /Applications/Postgres.app -name "pg_config"`.chomp
  end
end

incdir = `"#{pg_config_path}" --includedir`.chomp
libdir = `"#{pg_config_path}" --libdir`.chomp

dir_config("mystic/postgres", incdir, libdir)

# Try to use runtime path linker option, even if RbConfig doesn't know about it.
# The rpath option is usually set implicit by dir_config(), but so far not on OS X.
if RbConfig::CONFIG["RPATHFLAG"].to_s.empty? && try_link('int main() {return 0;}', " -Wl,-rpath,#{libdir}")
  $LDFLAGS << " -Wl,-rpath,#{libdir}"
end

abort "Can't find the PostgreSQL client library (libpq)" unless
	have_library('pq', 'PQconnectdb', ['libpq-fe.h']) ||
	have_library('libpq', 'PQconnectdb', ['libpq-fe.h']) ||
	have_library('ms/libpq', 'PQconnectdb', ['libpq-fe.h'])

create_makefile "mystic/postgres"
