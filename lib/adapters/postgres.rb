#!/usr/bin/env ruby

require "adapter"

=begin
  t.string
  t.text
  t.integer
  t.float
  t.decimal
  t.datetime
  t.timestamp
  t.time
  t.date
  t.binary
  t.boolean
=end

POSTGRES_SIZES = {
  # boolean
  :boolean => 1,
  
  # numerical
  :smallint => 2,
  :integer => 4,
  :bigint => 8,
  :decimal => -1,
  :numeric => -1,
  :real => 4,
  :double_precision => 8,
  :smallserial => 2,
  :serial => 4,
  :bigserial => 8,
  
  # geometric/spatial
  # n is the number of points
  :point => 16,
  :line => 32,
  :lseg => 32,
  :box => 32, # 16+16n bytes
  :path => -1, # 16+16n bytes
  :polygon => -1, # 40+16n bytes
  :circle => 24,
  
  
}

class PostgresAdapter < Adapter
  
  def size_hash
    return POSTGRES_SIZES
  end
  
  def column(type)
    
  end
  
end