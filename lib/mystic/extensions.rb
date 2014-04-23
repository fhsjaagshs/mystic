#!/usr/bin/env ruby

require "pathname"

module Mystic
  class Array
    def merge_keys(keys)
      raise ArgumentError, "Argument array must have the same number of elements as the receiver of this method." if keys.count != self.count
      Hash[each_with_index.map{ |obj,i| [keys[i],obj] }]
    end
  end

  class Hash
    #def sql_stringify(pair_separator=" ")
    #  map { |pair| pair * pair_separator } * ","
    #end
    
    def sqlize
      Hash[reject{ |key, value| value.to_s.empty? }.map{ |pair| "#{pair.first.to_s.sanitize}='#{pair.last.to_s.sanitize}'" }]
    end
  end

  class String
    def sqlize
      downcase.split("_").map(&:capitalize) * " "
    end
  
    def sanitize
      Mystic.sanitize(self).untaint
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
    
    def self.app_root(path=Dir.pwd)
      mystic_dir_path = expand_path("mystic",path)
      return path if exists?(mystic_dir_path) && directory?(mystic_dir_path)
      app_root(dirname(path)) unless path.length == 1
    end
  end
end