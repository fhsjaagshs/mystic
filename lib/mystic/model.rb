#!/usr/bin/env ruby

module Mystic
  class Model
    attr_accessor :attributes
    
    def table_name
      self.class.table_name
    end
    
    def self.table_name
      self.to_s.downcase[1..-2]
    end
    
    def initialize
      @attributes = {}
    end
    
    def self.generate_objs(obj)
      case obj
      when Array and obj.first.is_a?(Hash)
        obj.map do |hash| 
          ret = self.new
          ret.attributes = obj
          ret
        end
      when Hash
        ret = self.new
        ret.attributes = obj
      else
        raise ArgumentError, "Cannot create #{self.class.to_s}(s) from #{obj.inspect}."
      end
    end
  end
end