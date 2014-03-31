#!/usr/bin/env ruby

require "connection_pool"

class Adapter
  
  def name
    class.name.split('::').last.gsub("Adapter","").downcase
  end
  
  def pool
    @pool
  end
  
  def pool=(new_pool)
    @pool = new_pool
  end
  
  def create_pool(&block)
    @pool = ConnectionPool::Wrapper.new(:size => 5, :timeout => 5, &block)
  end
  
  def pool_instance
    inst = nil
    @pool.with do |instance|
      inst = instance
    end
    return inst
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