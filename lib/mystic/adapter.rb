#!/usr/bin/env ruby

require "connection_pool"

UNIVERSAL_TYPES = {
  :date => "DATE",
  :time => "TIME",
  :timestamp => "TIMESTAMP"
  :bool => "BOOLEAN",
  :text => "TEXT",
  :integer => "INTEGER",
  :varchar => "VARCHAR"
}

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
  
  def column_sql(name, kind, size, constraints)
    ""
  end
  
  def kind(kind)
    UNIVERSAL_TYPES[kind.to_sym]
  end
end