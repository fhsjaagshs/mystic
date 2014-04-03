#!/usr/bin/env ruby

module Mystic
  class ConnectionPool
    
    def initialize(opts={}, &block)
      @creation_block = &block
      @size = opts[:size].to_i
      @size ||= opts["size"].to_i
    end
    
    
    
  end
end