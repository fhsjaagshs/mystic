#!/usr/bin/env ruby

require "pathname"

class String
  def sqlize
    self.capitalize.split("_").join(" ")
  end
end

class Symbol
  def sqlize
    self.to_s.sqlize
  end
end

class File
  def self.git_root
    results = `git rev-parse --show-toplevel`.strip
    return results[0..4] == "fatal" ? nil : results
  end

  # interate through filesystem to find config.ru or app.rb
  # In most situations, config.ru or app.rb is in the application root
  def self.find_app_root(path)
    files = Dir.entries(path)
    path if files.include?("config") && files.include?("mystic")
    File.find_app_root(File.dirname(path)) if path.length > 0
  end
  
  def self.script_dir
    File.dirname(File.expand_path($0)) + "/"
  end
  
  def self.app_root
    puts "HERE"
    g = File.git_root
    a = File.find_app_root(Dir.pwd)
    puts a
    return a.length > g.length ? a : g
  end
end