#!/usr/bin/env ruby

require "pathname"

module Kernel
	def self.silent
		v = $VERBOSE
		$VERBOSE = false
		yield
		$VERBOSE = v
		nil
	end
end

class String
  def escape
    Mystic.escape(self).untaint
  end
	
	def terminate term=";"
    strip.end_with?(term) ? self + term : self
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
    r
  end
  
  def merge_keys *keys
		raise ArgumentError, "No keys to merge." if keys.nil? || keys.empty?
    raise ArgumentError, "Argument array must have the same number of elements as self." if keys.count != count
    Hash[each_with_index.map { |v,i| [keys[i],v] }]
  end
	
	def symbolize
		map(&:to_sym)
	end
	
	def symbolize!
		map!(&:to_sym)
	end
	
	def sqlize
		map { |o|
			case o
			when String
				"'#{o.escape}'"
			when Numeric
				o.to_s
			end
		}.compact
	end
end

class Hash
	def subhash *keys
		Hash[values_at(*keys).merge_keys(*keys).reject{ |k,v| v.nil? }]
	end
	
	def symbolize
		Hash[map { |k,v| [k.to_sym, v]}]
	end
	
	def symbolize!
		keys.each { |key| self[key.to_sym] = delete key }
	end
  
  def sqlize
    reject { |k,v| v.nil? || (v.empty? rescue false) }.map { |pair| pair.sqlize.join '=' }
  end
end

class Pathname
	Kernel.silent do
		def to_s
			@path
		end
		
	  def relative?
	    @path[0] != File::SEPARATOR
	  end
	
		def join *args
			Pathname.new(File.join @path, *args.map(&:to_s))
		end
	end
end