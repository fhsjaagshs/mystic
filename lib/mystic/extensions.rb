#!/usr/bin/env ruby

require "pathname"

APP_ROOT_FILENAMES = ["mystic", "config", "app.rb"]

class Hash
  def sql_stringify
    self.inject([]) { |array, key, value| array << key + " " + value }.join(",")
  end
end

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
  
  def self.find_app_root(path)
    targets = Dir.entries(path).select { |filename| APP_ROOT_FILENAMES.include?(filename) }
    return nil if targets.count == 0 && path.length == 1
    return path if targets.count > 0
    return File.find_app_root(File.dirname(path))
  end

  def self.script_dir
    File.dirname(File.expand_path($0)) + "/"
  end
  
  def self.app_root
    g = File.git_root
    a = File.find_app_root(Dir.pwd.to_s)
    return a.length > g.length ? a : g
  end
end