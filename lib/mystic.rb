#!/usr/bin/env ruby

require "mystic/mystic-migration"
require "mystic/extensions"
require "mystic/sql"
require "mystic/adapter"
require "mystic/model"

module Mystic
  @@adapter = nil
  
  def self.adapter
    path = File.app_root + "/config/mystic.rb"
    nil unless File.exists?(path)
    @@adapter ||= eval(File.read(path))
  end
  
  def self.connect(opts={})
    return false unless opts.member?(:adapter)
    adapter_name = opts.delete(:adapter).to_s

    require "mystic/adapters/" + adapter_name
    adapter_class = adapter_name.capitalize + "Adapter"
    @@adapter = Object.const_get(adapter_class).new
    
    return false if @@adapter.nil?
    self.adapter.connect(opts)
    true
  end
  
  def self.execute(sql)
    adptr = self.adapter
    adptr.nil? ? nil : adptr.exec(sql)
  end
  
  def self.sanitize(string)
    adptr = self.adapter
    adptr.nil? ? nil : adptr.sanitize(string)
  end
end