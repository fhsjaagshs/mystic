#!/usr/bin/env ruby

require "connection_pool"

class Adapter
  
  def name
    self.class.name.split('::').last.gsub("Adapter","").downcase
  end
  
  def create_pool(&block)
    @pool = ConnectionPool::Wrapper.new(:size => 5, :timeout => 5, &block)
  end
  
  def connect(opts)
    
  end
  
  def exec(sql)
    
  end
  
  def size_hash
    {}
  end
  
  def column_sql(type,name,opts)
    ""
  end
  
  def max_length_for(type_symbol)
    return size_hash[type_symbol]  
  end
end