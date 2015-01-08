#!/usr/bin/env ruby

require_relative "./lib/mystic"


username = ENV['USER'] || ENV['USERNAME']

p = Mystic::Postgres.new :user => username, :password => "", :dbname => username, :port => 5432, :host => "localhost"
#raise p.error unless p.valid?
puts p.execute("SELECT false::boolean as \"boolean\", 0::integer as \"integer\", 'I am a programmer'::text as \"text\", 5::money as \"money\", 3.141592654::numeric as \"float\" ;")
#puts p.execute("SELECT false::boolean as \"boolean\"")
#puts p.execute("SELECT false::boolean as cares_about_stupid_shit, 0::integer as fucks_given, 'I am a programmer'::text as truth;").inspect
puts p.escape_identifier("sdfghj56")
puts p.escape_literal("sdfghj56")
puts p.escape_string("sdfghj56")

p.execute "LISTEN \"foobar\"" # to trigger it, Mystic.execute "perform pg_notify('foobar', '');"
p.wait_for_notify 10000
p.execute "UNLISTEN \"foobar\""

p.disconnect!
#raise StardardError, p.error unless !p.valid?
