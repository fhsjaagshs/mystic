#!/usr/bin/env ruby

require "mystic"
require "connection_pool"
require "densify"

# TODO: Store blocks in hash to avoid conflicts between adapters

module Mystic
  class Adapter
    attr_accessor :pool_size, :pool_timeout, :env
  
    @@blocks = {}
  
		def initialize(opts={})
			@env = opts[:env] || opts["env"]
		end
	
    # Get the adapter name (examples: postgres, mysql)
    def self.adapter
      name.split("::").last.delete("Adapter").downcase
    end
    
    # Map a block to an adapter's block hash
    #   This avoids cases where a subclass' class var
    #   changes that class var on its superclass
    def self.map_block(key, block)
			@@blocks[self.adapter] ||= {}
      @@blocks[self.adapter][key] = block
    end
    
    # Fetch a block for the current adapter
    def block_for(*args)
			key = args.delete(-1)
      @@blocks[args.first || self.class.adapter][key] rescue lambda { "" }
    end
    
    #
    # Adapter DSL
    #
		
    # Return native Ruby types from an SQL query
    def self.execute(&block)
      map_block :execute, block
    end
  
    # Sanitize a string
    def self.sanitize(&block)
      map_block :sanitize, block
    end
  
    # Create an instance of a connection gem
    def self.connect(&block)
      map_block :connect, block
    end
  
    # Close an instance of a connection gem
    def self.disconnect(&block)
      map_block :disconnect, block
    end
		
		# Map missing methods to SQL generation
		def self.method_missing(meth, *args, &block)
			map_block meth, block
		end
  
    #
    # Adapter methods
    #   These are called internally
    #   They are called by class methods
    #   in ../mystic.rb
    #
  
    def connect(opts)
      @pool = ConnectionPool.new(
        :size => pool_size || 5,
        :timeout => pool_timeout || 5,
      ) { block_for(:connect).call(opts) }
    end
  
    def disconnect
      @pool.shutdown(&block_for(:disconnect))
    end
  
    def execute(sql)
      nil if @pool.nil?
      sql = sql.densify
      sql << ";" unless sql[-1] == ";"
    
      res = nil
      @pool.with { |inst| res = block_for(:execute).call(inst,sql) }
      res
    end
  
    def sanitize(str)
      res = nil
      @pool.with { |inst| res = block_for(:sanitize).call(inst,sql) }
      res
    end
  
    def serialize_sql(obj)
			case obj
			when SQL::Table
				block_for(:table).call(obj)
			when SQL::Index
				block_for(:index).call(obj)
			when SQL::Column
				block_for(:column).call(obj)
			when SQL::Operation
				block_for(obj.kind).call(sql_obj)
				obj.callback.call unless obj.callback.nil?
			end
    end
  end
end