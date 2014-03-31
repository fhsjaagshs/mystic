#!/usr/bin/env ruby

require "pathname"

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
    
    return path == "/" ? nil : File.check_for_config_ru(newpath)
  end
  
  def self.script_path
    File.expand_path(File.dirname(File.dirname(__FILE__)))
  end
  
  def self.app_root
    root = File.git_root
    
    if root.nil?
      root = File.check_for_config_ru(File.script_path)
    end
    
    return root
  end
end