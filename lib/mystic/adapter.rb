#!/usr/bin/env ruby

require "densify"
require "access_stack"

module Mystic
  class Adapter
    attr_accessor :pool_size,
									:pool_timeout,
									:pool_expires
  
    @@blocks = {}

    def self.create(name="",opts={})
			name = name.to_s.downcase.strip
			name = "postgres" if name =~ /^postg.*$/i # Includes PostGIS
			name = "mysql" if name =~ /^mysql.*$/i
		
			require "mystic/adapters/" + name
		
			Object.const_get("Mystic::#{name.capitalize}Adapter").new opts
    end
    
    def initialize(opts={})
    	opts.symbolize.each do |k,v|
    		k = ('@' + k.to_s).to_sym
    		instance_variable_set k,v if instance_variables.include? k
    	end
    end
	
    # Gets the adapter name (examples: postgres, mysql)
    def self.adapter
      a = name.split("::").last.sub("Adapter","").downcase
			a = "abstract" if a.empty?
			a
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
    	b = @@blocks[adapter][key] rescue nil
			b ||= @@blocks["abstract"][key] rescue nil
			b ||= lambda { "" }
			b
    end
    
    #
    # Adapter DSL
    # Implemented using method_missing
    #
    
    # example
    # execute do |inst,sql|
    #   inst.exec sql
    # end
    
    # execute(inst,sql)
    # Executes SQL and returns Ruby types
    
    # TODO: different kinds of escaping: ident & quote
    
    # sanitize(inst,sql)
    # Escapes a literal
    
    # connect(opts)
    # Creates an instance of the DB connection
    
    # disconnect(inst)
    # Disconnects and destroys inst (a database connection)
    
    # validate(inst)
    # Checks if inst is a valid connection

		# Map missing methods to blocks
		# DB ops or SQL generation
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
			disconnect unless @pool.nil?
			@pool = AccessStack.new(
				:size => @pool_size,
				:timeout => @pool_timeout,
				:expires => @pool_expires,
				:create => lambda { block_for(:connect).call opts }
			)
    end
  
    def disconnect
    	@pool.destroy ||= block_for :disconnect
			@pool.empty!
    end
    
    def reap
    	@pool.validate ||= block_for :validate
    	@pool.reap
    end
  
    def execute(sql)
			raise AdapterError, "Adapter's connection pool doesn't exist and so Mystic has not connected to the database." if @pool.nil?
			@pool.with { |inst| block_for(:execute).call inst, sql }
    end
  
    def sanitize(str)
			@pool.with { |inst| block_for(:sanitize).call inst, str }
    end
		
		def json_supported?
			block_for(:json_supported).call
		end
  
    def serialize_sql(obj)
			return case obj
			when SQL::Table
				block_for(:table).call obj
			when SQL::Index
				block_for(:index).call obj
			when SQL::Column
				block_for(:column).call obj
			when SQL::Operation
				res = block_for(obj.kind).call obj
				obj.callback.call unless obj.callback.nil?
				res
			end
    end
  end
end