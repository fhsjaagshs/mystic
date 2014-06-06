#!/usr/bin/env ruby

class String
  def sqlize
    downcase.split("_").map(&:capitalize)*' '
  end

  def sanitize
    Mystic.sanitize(self).untaint
  end
end

class Symbol
  def sqlize
    to_s.sqlize
  end
  
	alias_method :sanitize, :sqlize
end

class Array
  def merge_keys(keys=[])
    raise ArgumentError, "Argument array must have the same number of elements as self." if keys.count != self.count
    Hash[each_with_index.map{ |obj,i| [keys[i],obj] }]
  end
	
	def sqlize
		map do |o|
			case o
			when String
				"'#{o.sanitize}'"
			when Numeric
				o.to_s
			end
		end
	end
end

class Hash
  def parify(delim=" ")
    Hash[map{ |pair| pair * delim }]
  end
	
	def symbolize
		Hash[map{ |k,v| [k.to_sym, v]}]
	end
	
	def symbolize!
		keys.each do |key|
			self[key] = delete(key).to_sym
		end
		self
	end
  
  def sqlize
    Hash[reject{ |k,v| v.empty? }.map{ |k,v| "#{k.sanitize}=#{v.is_a?(String) ? "'#{v.sanitize}'" : v }" }]
  end
end

class File
  def self.git_root
    res = `git rev-parse --show-toplevel`.strip
    res unless res =~ /^fatal.*/
  end
end