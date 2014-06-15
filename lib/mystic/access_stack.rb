#!/usr/bin/env ruby

require "thread"

=begin
AccessStack.new(
	:size => 10,
	:timeout => 3, # how long to wait for access to the stack
	:expires => 5, # how long an object lasts in the stack
	:create => lambda {
		PG.connect
	},
	:destroy => lambda { |instance|
		instance.close
	}
)
=end

# TODO: Expire objects

module Mystic	
	class AccessStack
		attr_reader :count
		attr_accessor :expires, :size, :create, :destroy
		
		TimeoutError = Class.new StandardError
		
		def initialize(opts={})
			@timeout = opts[:timeout] || opts["timeout"] || -1
			@size = opts[:size] || opts["size"] || 5
			@expires = opts[:expires] || opts["expires"] || -1
			@expr_hash = {}
			@stack = []
			@count = 0
			@mutex = Mutex.new
			@create = opts[:create] || opts["create"]
			@destroy = opts[:destroy] || opts["destroy"]
		end
		
		def threadsafe(timeout=-1,&block)
			start_time = Time.now
			while @mutex.locked?
				sleep timeout/7
				raise TimeoutError, "Took too long for the mutex to get a lock." if (Time.now-start_time).to_f >= timeout && timeout > 0
			end
			
			@mutex.lock if @mutex.try_lock
			return false unless @mutex.owned?
			block.call	
			@mutex.unlock
			true
		end
		
		def create_obj
			obj = @create.call
			@expr_hash[obj] = Time.now
			obj
		end
				
		def with(&block)
			begin
				obj = nil
				
				threadsafe @timeout do
					obj = @stack.pop
					
					if @expr_hash[obj]-Time.now > @expires
						obj = nil
						@count -= 1
					end
					
					if @count < @size && obj.nil?
						@count += 1
						obj = create_obj
					end
				end

				return block.call obj
			ensure
				threadsafe do
					@stack.push obj
				end
			end
		end
		
		def empty
			threadsafe do
				@stack.each { |instance| @destroy.call instance }
				@expr_hash.clear
				@stack.clear
				@count = 0
			end
		end
		
		# Creates #{num} objects and adds them to the stack
		# Returns: the number of objects created
		def create(num=1)
			created_count = 0
			
			threadsafe do
				num.times do
					if @count < @size
						@stack.push create_obj
						@count += 1
						created_count += 1
					end
				end
			end
				
			created_count
		end
	end
end