#!/usr/bin/env ruby

require "mystic/mystic-migration"
require "mystic/extensions"
require "mystic/minify"
require "mystic/sql"
require "mystic/adapter"

module Mystic
  @@adapter = nil
  
  def self.adapter
    puts "THIS"
    eval(File.read(File.app_root + "/config/mystic.rb")) if @@adapter == nil
    return @@adapter
  end
  
  def self.connect(opts={})
    adapter_name = opts.delete(:adapter).to_s
    
    if adapter_name.length > 0
      adapter_class = adapter.to_s.capitalize + "Adapter"
      require "mystic/adapters/" + adapter
      @@adapter = Object.const_get(adapter_class).new
    end

    return false if @@adapter.nil?
    Mystic.adapter.connect(opts)
    return true
  end
  
  def self.execute(sql)
    adptr = Mystic.adapter
    return nil if adptr.nil?
    adptr.exec(sql.minify)
  end
  
  def self.sanitize(string)
    adptr = Mystic.adapter
    return nil if adptr.nil?
    adptr.sanitize(string)
  end
end