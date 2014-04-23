#!/usr/bin/env ruby

require "pathname"

module Mystic
  # These two things abuse the structure of hashes as [[:key,"value"],[:key,"value"]]
  class Array
    def merge_keys(keys)
      raise ArgumentError, "Argument array must have the same number of elements as the receiver of this method." if keys.count != self.count
      Hash[each_with_index.map{ |obj,i| [keys[i],obj] }]
    end
  end

  class Hash
    def sql_stringify(pair_separator=" ")
      map { |pair| pair * pair_separator } * ","
    end
  end

  class String
    def sqlize
      downcase.split("_").map(&:capitalize)*" "
    end
  
    def sanitize
      sanitized = Mystic.sanitize(self)
      sanitized.untaint if tainted? # may not be suitable
      sanitized
    end
  end

  class Symbol
    def sqlize
      to_s.sqlize
    end
  end

  class File  
    def self.git_root
      res = `git rev-parse --show-toplevel`.strip
      return nil if res[0..4] == "fatal"
      res
    end
  
    def self.find_app_root(path)
      mystic_dir_path = expand_path("mystic",path)
      return path if exists?(mystic_dir_path) && directory?(mystic_dir_path) # return is necessary
      return nil if path.length == 1 # return is necessary
      find_app_root(dirname(path))
    end

    def self.script_dir
      File.dirname(File.expand_path($0)) + "/"
    end
  
    def self.app_root
      File.find_app_root(Dir.pwd)
    end
  end
end