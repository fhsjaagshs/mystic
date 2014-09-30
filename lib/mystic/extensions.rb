#!/usr/bin/env ruby

require "pathname"

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

class File
  def self.write f, d
    open(f.to_s, 'w') { |file| file.write d }
  end
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

# Public
class ::String
  def escape
		Mystic.escape self
  end
  
  def quote
    Mystic.quote self
  end
  
  def dblquote
    Mystic.dblquote self
  end
end

class Array
  def unify_args
    r = {}
    each do |arg|
      case arg
      when Hash then r.merge!(arg)
      else r[arg] = true end
    end
    r.symbolize
  end
  
  def merge_keys *keys
		raise ArgumentError, "No keys to merge." if keys.nil? || keys.empty?
    raise ArgumentError, "Argument array must have the same number of elements as self." if keys.count != count
    Hash[keys.zip(self)]
  end
	
	def symbolize
		map { |e| e.to_s.to_sym }
	end
	
	def symbolize!
		map! { |e| e.to_s.to_sym }
	end
end

class ::Object
  def sqlize
		case self
    when nil then "NULL"
		when String then quote
    when Symbol then dblquote # symbols are assumed to be SQL identifiers
		when Numeric then to_s.escape
    when DateTime then to_s.quote
    when Date then to_s.quote
    when Time then to_s.quote
    else raise TypeError, "Unable to turn type into an SQL type." end
  end
end

class ::Array
	def sqlize
    map(&:sqlize)
	end
end

class Hash
	def subhash *keys
		Hash[values_at(*keys).merge_keys(*keys).reject{ |k,v| v.nil? }]
	end
	
	def symbolize
    r = dup
		r.symbolize!
    r
	end
	
	def symbolize!
    dup.each_key do |k|
      _v = delete k
      _v.symbolize! if _v.is_a? Hash
      self[k.to_sym] = _v
    end
	end
end

class ::Hash
  def sqlize
    map { |p| p.sqlize*'=' }
  end
end

Kernel.silent do
  class Pathname
  	def to_s
  		@path
  	end
	
    def relative?
      @path[0] != File::SEPARATOR
    end

  	def join *args
  		Pathname.new File.join(@path, *args.map(&:to_s))
  	end
  end
end
