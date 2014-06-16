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
	},
	:validate => lamda { |instance|
		instance.status == CONNECTION_OK
	}
)
=end

# TODO: Expire objects on a timer

module Mystic	
	class AccessStack
		attr_reader :count
		attr_accessor :expires, :size, :create, :destroy, :validate
		
		TimeoutError = Class.new StandardError
		
		def initialize(opts={})
			@timeout = opts[:timeout] || opts["timeout"] || 5
			@size = opts[:size] || opts["size"] || 5
			@expires = opts[:expires] || opts["expires"] || -1
			@expr_hash = {}
			@stack = []
			@count = 0
			@mutex = Mutex.new
			@create = opts[:create] || opts["create"]
			@destroy = opts[:destroy] || opts["destroy"]
			@validate = opts[:validate] || opts["validate"]
		end
		
		def with(&block)
			begin
				obj = nil
				
				threadsafe @timeout do
					obj = @stack.pop
				end
				
				if !(obj_valid obj)
					obj = nil
					@count -= 1
				end
				
				if @count < @size && obj.nil?
					@count += 1
					obj = create_obj
				end

				return block.call obj
			ensure
				threadsafe do
					@stack.push obj
				end
			end
		end
		
		def empty
			return if @count == 0
			threadsafe @timeout do
				@stack.each(&@destroy.method(:call))
				@expr_hash.clear
				@stack.clear
				@count = 0
			end
		end
		
		def reap
			return true if @count == 0
			threadsafe @timeout do
				@stack.reject(&method(:obj_valid)).each do |instance|
					@destroy.call instance
					@expr_hash.delete instance
					@stack.delete instance
					@count -= 1
				end
			end
		end

		def create_objects(num=1)
			created_count = 0
			
			threadsafe @timeout do
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
		
		def empty?
			@count == 0
		end
		
		private
		
		def threadsafe(timeout=-1,&block)
			begin
				@mutex.lock
				block.call
				@mutex.unlock
			rescue
				
			end
		end
=begin
		def threadsafe(timeout=-1,&block)
			puts "threadsafe()"
			start_time = Time.now
			while @mutex.locked? do
				sleep timeout/10 if timeout > 0
				sleep 0.5 if timeout == -1
				puts "loop"
				raise TimeoutError, "Took too long for the mutex to get a lock." if (Time.now-start_time).to_f >= timeout && timeout > 0
			end
			
			puts "about to lock"
			
			if @mutex.try_lock
				@mutex.lock 
				block.call
				@mutex.unlock
			end
			
			true
		end
=end
		def create_obj
			obj = @create.call
			@expr_hash[obj] = Time.now
			obj
		end
		
		def obj_valid(obj)
			block_valid = @vaildate.call obj rescue true
			expired = (@expires > 0 && (@expr_hash[obj] || 0).to_f-Time.now.to_f > @expires)
			!expired && block_valid
		end
	end
end