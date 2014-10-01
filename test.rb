#!/usr/bin/env ruby

require "./lib/mystic/postgres"
$DEBUG = true
p = Mystic::Postgres.connect :dbname => "tests", :host => "localhost", :port => 5432
raise p.error unless p.valid?
puts p.execute("SELECT 0 as fucks_given;").inspect
puts p.quote_ident "sdfghj56"
p.disconnect!
raise StardardError, p.error unless !p.valid?

