#!/usr/bin/env ruby

require "pg"
require "connection_pool"

module Mystic
  class Connection
    def self.execute(sql)
      res = nil
      @@pool.with do |postgres|
        res = postgres.exec(sql)
      end
      return res
    end
    
    def self.sanitize(string)
      res = nil
      @@pool.with do |postgres|
        res = postgres.escape_string(string)
      end
      return res
    end
    
    def self.connect(opts={})
      @@pool = ConnectionPool::Wrapper.new(:size => 5, :timeout => 5) { PG.connect(opts) }
    end
  end  
end