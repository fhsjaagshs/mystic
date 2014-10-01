#!/usr/bun/env ruby

require "./lib/mystic/postgres"
$DEBUG = true
p = Mystic::Postgres.connect :dbname => "tests", :host => "localhost", :port => 5432
puts "#{p} is #{p.valid? ? "valid" : "invalid"}."
puts p.execute("SELECT 0 as fucks_given;").inspect
p.disconnect!
puts "#{p} is #{p.valid? ? "valid" : "invalid"}."