#!/usr/bin/env ruby

require "mystic-connection"
require "mystic-migration"

module Mystic
  
  def self.adapter
    return @@adapter
  end
  
  def self.adapter=(adapter)
    # this creates the adapter object
    @@adapter = Object.const_get(adapter.to_s.capitalize + "Adapter").new
    
    return @@adapter != nil
  end
  
  def self.connect(opts={})
    Mystic.adapter = opts[:adapter].to_sym
    Mystic::Connection.connect(opts)
  end
  
  def self.execute(sql)
    Mystic::Connection.execute(sql)
  end
  
  def self.sanitize(string)
    Mystic::Connection.sanitize(string)
  end
end