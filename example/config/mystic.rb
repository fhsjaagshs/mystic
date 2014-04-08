#!/usr/bin/env ruby

require "mystic"

# pass params as you would for
# the db gem you're using.

# the below config is for the pg gem for postgresql
Mystic.connect(
  :adapter => "postgres" # This is not part of pg's PG.connect hash...
  :dbname => "test",
  :port => 5432,
  :user => "example",
  :password => "50M37H1NG_53CR3T!!!"
)