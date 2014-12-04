#!/usr/bin/env ruby

require "pathname"

#
# Public
#

module ::Kernel
	def silent
		v = $VERBOSE
		$VERBOSE = false
		yield
		$VERBOSE = v
		nil
	end
  
  def require_recursive path
    raise ArgumentError, "A path is required. Ha. Required." if path.nil? || path.empty?
    Dir.glob(File.join(path,"/**/*.rb"), &method(:require))
  end
end

class ::String
  def escape; Mystic.escape self; end
  def quote; Mystic.quote self; end
  def dblquote; Mystic.dblquote self; end
end

class ::Hash
  def sqlize; map { |p| p.sqlize*'=' }; end
end

class Exception
  alias_method :initialize_original, :initialize
  
  class << self
    attr_accessor :default_message
    
    def with_message msg
      @global_message ||= nil
      e = Class.new self
      e.default_message = msg
      e
    end
  end
  
  def initialize msg=nil
    initialize_original msg || self.class.default_message
  end
end

#
# Private
#

class File
  def self.write path=nil, data=""
    raise ArgumentError, "Invalid path." if path.nil? || path.empty? || !path.writeable?
    new(path.to_s, 'w').write data
  end
end

class Object
  def symbolize!; self; end
  def symbolize; self; end
end

# Internal
class String
	def terminate t=";"
    match(/^.*#{t}\s*$/).nil? ? self + t : self
	end
  
  def numeric?
    true if Float self rescue false
  end
end

class Array
  def unify_args
    Hash[map { |arg|
      case arg
      when Hash then arg.symbolize.to_a
      else [(arg.to_sym rescue arg.inspect), true] end
    }.flatten.each_slice(2).to_a]
  end
  
  def merge_keys *keys
		raise ArgumentError, "No keys to merge." if keys.nil? || keys.empty?
    raise ArgumentError, "Argument array must have the same number of elements as self." if keys.count != count
    Hash[keys.zip(self)]
  end
	
	def symbolize; map { |e| e.to_s.to_sym }; end
	def symbolize!; map! { |e| e.to_s.to_sym }; end
end

class ::Object
  def sqlize
		case self
    when nil then "NULL"
    when respond_to?(:to_str) then to_str
		when String then quote
    when Symbol then to_s.dblquote # symbols are assumed to be SQL identifiers
		when Numeric then to_s.escape
    when DateTime then to_s.quote
    when Date then to_s.quote
    when Time then to_s.quote
    else raise TypeError, "Unable to turn type into an SQL type." end
  end
end

class ::Array
	def sqlize; map(&:sqlize); end
end

class Hash
	def subhash *keys
		Hash[values_at(*keys).merge_keys(*keys).reject{ |k,v| v.nil? }]
	end
	
	def symbolize
    keys.each_with_object({}) { |k,h| h[k.to_sym] = self[k].symbolize  }
	end
	
	def symbolize!
    keys.each { |k| self[k.to_sym] = delete(k).symbolize!  }
	end
end
