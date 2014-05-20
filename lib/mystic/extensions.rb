#!/usr/bin/env ruby

module Mystic
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
    
    def sanitize
      to_s.sanitize
    end
  end
  
  class Array
    def merge_keys(keys)
      raise ArgumentError, "Argument array must have the same number of elements as the receiver/callee of this method." if keys.count != self.count
      Hash[each_with_index.map{ |obj,i| [keys[i],obj] }]
    end
  end

  class Hash
    def parify(delimiter=" ")
      map{ |pair| pair * delimiter }
    end
    
    def sqlize
      Hash[reject{ |k,v| v.empty? }.map{ |k,v| "#{k.sanitize}='#{v.sanitize}'" }]
    end
  end

  class File  
    def self.git_root
      res = `git rev-parse --show-toplevel`.strip
      return nil if res =~ /^fatal.*/
      res
    end
    
    def self.app_root(path=Dir.pwd)
      mystic_dir_path = expand_path("mystic",path)
      return path if exists?(mystic_dir_path) && directory?(mystic_dir_path)
      app_root(dirname(path)) unless path.length == 1
    end
  end
end