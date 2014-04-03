#!/usr/bin/env ruby

require "mystic"

# this file should be at
# config/mystic.rb

# setup your adapter
Mystic.adapter = "postgres"

# pass params as you would for
# the db gem you're using.

# the below config is for the pg gem for postgresql
Mystic.connect(
  :adapter => "postgres" # alternatively, you can set the adapter here
  :dbname => "test",
  :port => 5432,
  :user => "example",
  :password => "50M37H1NG_53CR3T!!!"
)