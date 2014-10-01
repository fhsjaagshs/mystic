#!/usr/bun/env ruby

require "./lib/mystic/postgres"

p = Mystic::Postgres.new :dbname => "tests", :host => "localhost", :port => 5432
puts p
puts p.valid?
r = p.execute "SELECT 0 as fucks_given"
puts r.inspect
p.disconnect!