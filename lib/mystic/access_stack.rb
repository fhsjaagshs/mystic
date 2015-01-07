#!/usr/bin/env ruby
require "timeout"

class AccessStack
	attr_reader :count,
              :create,
              :destroy,
              :validate
  attr_accessor :pool,
                :checkout_timeout,
                :reaping_frequency,
                :dead_connection_timeout

	TimeoutError = Class.new StandardError
  DestructorError = Class.new StandardError
  CreatorError = Class.new StandardError
  
  NO_DESTRUCTOR_MSG = "This pool is lacking a constructor block."
  NO_CONSTRUCTOR_MSG = "This pool is lacking a destructor block."
  
=begin
  pool - size of pool (default 5)
  checkout_timeout - number of seconds to wait when getting a connection from the pool
  reaping_frequency - number of seconds to run the reaper (nil means don't run the reaper)
  dead_connection_timeout - number of seconds after which the reaper will consider a connection dead. (default 5 seconds)
=end

	def initialize params={}
    @mutex = Mutex.new
    opts = params.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
    
    @pool = opts[:pool] || 5
    @checkout_timeout = opts[:checkout_timeout] || 5
    reaping_frequency = opts[:reaping_frequency] || 0 # setter starts autoreaping
    @dead_connection_timeout = opts[:dead_connection_timeout] || 5
    
		@expr_hash = {}
		@stack = []
		@count = 0
		@create = opts[:create]
		@destroy = opts[:destroy]
		@validate = opts[:validate]
	end
  
  # contructor/destructor/validator blocks
  def create &block; @mutex.synchronize { @create = block }; end
  def destroy &block; @mutex.synchronize { @destroy = block }; end
  def validate &block; @mutex.synchronize { @validate = block }; end
  
	def empty?; @count.zero?; end
  def full?; @count == @pool; end
  def available?; @stack.count > 0 && !empty?; end # whether or not you can get an object from the pool
  def autoreaping?; @reaping_frequency > 0; end
  
  def pool= v; @mutex.synchronize { @pool = v }; end
  def checkout_timeout= v; @mutex.synchronize { @checkout_timeout = v }; end
  def dead_connection_timeout= v; @mutex.synchronize { @dead_connection_timeout = v }; end
  
  def reaping_frequency= v
    @mutex.synchronize { @reaping_frequency = v }
    start_autoreap if autoreaping?
  end
  
  
  def delete obj
    return obj if obj.nil?
    @mutex.synchronize do
      @count -= 1 if @stack.include? obj
  		@destroy.call(@stack.delete(@expr_hash.delete(obj)) || obj)
    end
    obj
  end
  
	def with
    raise CreatorError, NO_CONSTRUCTOR_MSG if @create.nil?
    raise DestructorError, NO_DESTRUCTOR_MSG if @destroy.nil?
    
		begin
      obj = @create.call if @stack.empty? # create one if needed
      obj ||= Timeout.timeout(@checkout_timeout, TimeoutError) { @mutex.synchronize { @stack.pop } } # otherwise load from @stack
    
      if !_obj_valid?(obj)
        delete obj
        obj = @create.call
      end
    
      @mutex.synchronize { @expr_hash[obj] = Time.now }

			yield obj
		ensure
      @mutex.synchronize { @stack.push obj } unless obj.nil?
		end
	end
	
	def reap!
    raise DestructorError, NO_DESTRUCTOR_MSG if @destroy.nil?
		return if empty?
    @mutex.synchronize { @stack.reject(&method(:_obj_valid?)).each(&method(:delete)) }
	end

	def clear!
		@mutex.synchronize do
      @count = 0
      @expr_hash.clear
			@stack.each(&@destroy.method(:call))
			@stack.clear
		end
	end

  # num - there are a few cases
  #   negative - fill pool so that there are num.abs free spots for objects in the pool
  #   positive - add num elements to the pool
  #   not passed - fill the pool completely
	def fill! num=@pool-@count
    raise CreatorError, NO_CONSTRUCTOR_MSG if @create.nil?
    
    return 0 if full?
    num = @pool-num.abs if num < 0
    return 0 if num <= 0
    
    objs = num.times.map(&@create.method(:call))
    expr_addition = objs.zip([Time.now]*num)
    
    @mutex.synchronize do
      @expr_hash.merge(expr_addition)
      @stack.push *objs
      @count += num
    end

		num
	end

	private

  def start_autoreap
    Thread.new do
      while autoreaping?
				sleep @reaping_frequency
				reap!
      end
    end
  end

	def _obj_valid? obj
    return false if obj.nil?
	  valid = obj.respond_to?(:valid?) ? obj.valid? : (@validate.nil? ? true : @vaildate.call(obj))
		expired = (@dead_connection_timeout > 0 && ((@expr_hash[obj] || Time.now)-Time.now).to_f > @dead_connection_timeout)
		!expired && valid
	end
end