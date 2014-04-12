#!/usr/bin/env ruby

module Mystic
  class Model
    attr_accessor :attributes
    
    def table_name
      self.class.to_s
    end
    
    def initialize
      @attributes = {}
    end
    
    def self.generate_objs(obj)
      case obj
      when Array and obj.first.is_a?(Hash)
        obj.map do |hash| 
          ret = self.class.new
          ret.attributes = obj
          ret
        end
      when Hash
        ret = self.class.new
        ret.attributes = obj
      else
        raise ArgumentError, "Cannot create #{self.class.to_s}(s) from #{obj.inspect}."
      end
    end
    
    def self.fetch(obj)
      return self.generate_objs(Mystic.parse_response(obj))
    end
    
    def to_json
      @attributes.to_json
    end
    
    def [](key)
      return @attributes[key]
    end
    
    def [](key, value)
      @attributes[key] = value if (key.is_a?(Symbol) || key.is_a?(String)) && (value.is_a?(Symbol) || value.is_a?(String))
    end
    
    def method_missing(meth, *args, &block)
      super if @attributes.member(meth.to_s) == false
      @attributes[meth]
    end
  end
end