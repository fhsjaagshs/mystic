#!/usr/bin/env ruby

require "mystic/mystic-migration"
require "mystic/extensions"
require "mystic/sql"
require "mystic/adapter"
require "mystic/model"

# require all adapters
Dir.glob("mystic/adapters/*.rb", &method(:require))

module Mystic
  @@adapter = nil
  
  def self.adapter
    @@adapter ||= eval(File.read(File.app_root + "/config/mystic.rb"))
  end
  
  def self.connect(opts={})
    adapter_name = opts.delete(:adapter).to_s
    return false if adapter_name.length == 0
    
    adapter_class = adapter_name.to_s.capitalize + "Adapter"
    require "mystic/adapters/" + adapter_name
    @@adapter = Object.const_get(adapter_class).new
    
    return false if @@adapter == nil
    self.adapter.connect(opts)
    return true
  end
  
  def self.execute(sql)
    adptr = self.adapter
    nil if adptr.nil?
    adptr.exec(sql)
  end
  
  def self.sanitize(string)
    adptr = self.adapter
    nil if adptr.nil?
    adptr.sanitize(string)
  end
end
