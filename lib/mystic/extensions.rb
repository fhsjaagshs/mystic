#!/usr/bin/env ruby

class ::String
  def escape; Mystic.escape self; end
  def quote; Mystic.quote self; end
  def dblquote; Mystic.dblquote self; end
end

class ::Object
  def sqlize
		case self
    when nil then "NULL"
    when respond_to?(:to_str) then to_str.quote
		when String then quote
    when Symbol then to_s.dblquote # symbols are assumed to be SQL identifiers
		when Numeric then to_s.escape
    when DateTime then to_s.quote
    when Date then to_s.quote
    when Time then to_s.quote
    when Array then map(&:sqlize)
    when Hash then map { |p| p.sqlize*'=' }
    else raise TypeError, "Unable to turn type into an SQL type." end
  end
  
  def symbolize doit=true
    case self
    when Hash then Hash[map { |k,v| [k.symbolize, v.symbolize(false)] }] # The goal is to symbolize all strings that are KEYS
    when Array then map(&:symbolize)
    when String then doit ? to_sym : self
    else self end
  end
  
  def symbolize!
    case self
    when Hash then keys.each { |k| self[k.to_sym] = delete(k).symbolize! }
    when Array then map! { |e| e.to_s.to_sym }
    else self end
  end
end

#
# Internal Helpers
#

class File
  def self.write path=nil, data=""; new(path.to_s, 'w').write data; end
end

class String
	def terminate t=";"; (end_with?(t) ? self : self+t); end
  def numeric?; (true if Float self rescue false); end
end

class Array
  # def method *args; args.unify_args; end
  # method :this => "that", :raw, :json, :flag, :that => "this"
  # => { :this => "that", :raw => true, :json => true, :flag => true, :that => "this" }
  def unify_args
    Hash[map { |arg|
      case arg
      when Hash then arg.symbolize.to_a
      else [(arg.to_sym rescue arg.inspect), true] end
    }.flatten.each_slice(2).to_a]
  end
end

class Hash
	def subhash *keys; Hash[keys.zip(values_at(*keys)).reject{ |k,v| v.nil? }]; end
end
