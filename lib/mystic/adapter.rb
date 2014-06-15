#!/usr/bin/env ruby

require "densify"
require "mystic/access_stack"

module Mystic
  class Adapter
    attr_accessor :pool_size, :pool_timeout
  
    @@blocks = {}
	
    # Gets the adapter name (examples: postgres, mysql)
    def self.adapter
      name.split("::").last.sub("Adapter","").downcase
    end
		
		def adapter
			self.class.adapter
		end
    
    # Map a block to an adapter's block hash
    #   This avoids cases where a subclass' class var
    #   changes that class var on its superclass
    def self.map_block(key, block)
			@@blocks[adapter] ||= {}
      @@blocks[adapter][key] = block
    end
    
    # Fetch a block for the current adapter
    def block_for(key)
      @@blocks[adapter][key] rescue lambda { "" }
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
			@pool = AccessStack.new(
				:size => @pool_size,
				:timeout => @pool_timeout,
				:create => lambda {
					block_for(:connect).call opts
				},
				:destroy => lambda { |instance|
					block_for(:disconnect).call(instance)
				}
			)
    end
  
    def disconnect
			@pool.empty
    end
  
    def execute(sql)
			raise AdapterError, "Adapter's connection pool doesn't exist and so Mystic has not connected to the database." if @pool.nil?
      sql = sql.densify
      sql << ";" unless sql[-1] == ";"
			
			@pool.with { |inst| block_for(:execute).call inst,sql }
    end
  
    def sanitize(str)
			@pool.with { |inst| block_for(:sanitize).call inst,sql }
    end
  
    def serialize_sql(obj)
			case obj
			when SQL::Table
				block_for(:table).call obj
			when SQL::Index
				block_for(:index).call obj
			when SQL::Column
				block_for(:column).call obj
			when SQL::Operation
				block_for(obj.kind).call obj
				obj.callback.call unless obj.callback.nil?
			end
    end
  end
end