#!/usr/bin/env ruby

require "mystic/mystic-migration"
require "mystic/extensions"
require "mystic/minify"
require "mystic/sql"
require "mystic/adapter"

module Mystic
  
  @@adapter = nil
  
  def self.adapter
    @@adapter ||= eval(File.read(File.app_root + "/config/mystic.rb"))
    @@adapter
  end
  
  # Ultra hacky string based object instantiation
  def self.adapter=(adapter)
    adapter_class = adapter.to_s.capitalize + "Adapter"
    require "mystic/adapters/" + adapter
    @@adapter = Object.const_get(adapter_class).new
  end
  
  def self.connect(opts={})
    adapter_name = opts.delete(:adapter)
    Mystic.adapter = adapter_name if adapter_name != nil
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