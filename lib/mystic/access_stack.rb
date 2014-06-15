#!/usr/bin/env ruby

require "thread"

=begin
AccessStack.new(
	:size => 10,
	:timeout => 3,
	:create => lambda {
		PG.connect {}
	},
	:destroy => lambda { |instance|
		instance.close
	}
)
=end

module Mystic	
	class AccessStack
		attr_reader :count
		
		def initialize(opts={})
			@timeout = opts[:timeout] || opts["timeout"] || -1
			@size = opts[:size] || opts["size"] || 5
			@stack = []
			@count = 0
			@mutex = Mutex.new
			@cvar = ConditionVariable.new
			@create_block = opts[:create] || opts["create"]
			@destroy_block = opts[:destroy] || opts["destroy"]
		end
		
		def with(&block)
			begin
				obj = nil
			
				@mutex.synchronize do
					@cvar.wait(@mutex) if @stack.count == 0 && @count > 0
					obj = @stack.pop
					if @count < @size && obj.nil?
						@count += 1
						obj = @create_block.call
					end
					@cvar.signal
				end

				return block.call obj
			ensure
				@mutex.synchronize do
					@stack.push obj
					@cvar.signal # Should it be @cvar.broadcast???
				end
			end
		end
		
		def empty
			@mutex.synchronize do
				@stack.each { |instance| @destroy_block.call(instance) }
				@stack.clear
				@count = 0
			end
		end
	end
end