#!/usr/bin/env ruby

require "mystic"
require "connection_pool"
require "densify"

# TODO: Store blocks in hash to avoid conflicts between adapters

module Mystic
  class Adapter
    attr_accessor :pool_size, :pool_timeout
  
    def self.adapter
      name.split('::').last.delete("Adapter").downcase
    end
  
    def adapter
      self.class.adapter
    end
  
    #
    # Adapter DSL
    #
  
    # Return SQL for an SQL object
    def self.sql(&block)
      @@sql_block = block
    end
  
    # Return native Ruby types from an SQL query
    def self.execute(&block)
      @@exec_block = block
    end
  
    # Sanitize a string
    def self.sanitize(&block)
      @@sanitize_block = block
    end
  
    # Create an instance of a connection gem
    def self.connect(&block)
      @@connect_block = block
    end
  
    # Close an instance of a connection gem
    def self.shutdown(&block)
      @@shutdown_block = block
    end
  
    #
    # Adapter methods
    #
  
    def connect(opts)
      @pool = ConnectionPool.new(
        :size => pool_size || 5,
        :timeout => pool_timeout || 5,
        @@connect_block.call(opts)
      )
    end
  
    def disconnect
      @pool.shutdown(&@@shutdown_block)
    end
  
    def execute(sql)
      nil if @pool.nil?
      sql = sql.densify
      sql << ";" unless sql[-1] == ";"
    
      res = nil
      @pool.with { |inst| res = @@exec_block.call(inst,sql) }
      res
    end
  
    def sanitize(str)
      res = nil
      @pool.with { |inst| res = @@sanitize_block.call(inst,sql) }
      res
    end
  
    def serialize_sql(sql_obj)
      @@sql_block.call(sql_obj)
    end
  end
end