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
    files = Dir.files[path]
    
    return path if files.include?("config.ru")
    return path if files.include?("app.rb")
    
    # this is the directory containing the passed path
    newpath = File.expand_path(File.dirname(path))
    
    return path == "/" ? nil : File.find_app_root(newpath)
  end
  
  def self.script_dir
    File.dirname(File.expand_path($0)) + "/"
  end
  
  def self.app_root
    root = File.git_root
    root ||= File.find_app_root(File.script_dir)
    return root
  end
end