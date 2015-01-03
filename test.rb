#!/usr/bin/env ruby

#require "./lib/mystic"

require "./lib/mystic/postgres"


username = ENV['USER'] || ENV['USERNAME']

p = Mystic::Postgres.connect :user => username, :password => "", :dbname => username, :port => 5432, :host => "localhost"
#raise p.error unless p.valid?
#puts p.execute("SELECT false::boolean as cares_about_stupid_shit, 0::integer as fucks_given, 'I am a programmer'::text as truth;").inspect
puts p.escape_identifier("sdfghj56").inspect
#puts p.escape_literal("sdfghj56").inspect
#puts p.escape_string("sdfghj56").inspect
p.disconnect!
#raise StardardError, p.error unless !p.valid?
