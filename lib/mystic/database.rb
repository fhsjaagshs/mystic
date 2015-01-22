#!/usr/bin/env ruby

require "uri"
require_relative "./access_stack"
require_relative "../../ext/mystic/postgres.bundle" # TODO: figure this out

module Mystic
  EnvironmentError = Class.new StandardError
  class << self
    def connect dbconf=nil, poolconf=nil
      disconnect if connected?
      ENV["DATABASE_URL"] = config.database_url dbconf
      @pool = AccessStack.new (poolconf || config.pool)
      @pool.create { @connected = true; Mystic::Postgres.new (dbconf || config.postgres) }
      @pool.destroy { |pg| (@connected = @pool.count-1 <= 0); pg.disconnect! }
      @pool.validate { |pg| pg != nil && pg.valid? }
      @connected = true
    end

    def disconnect
      @connected = false
      @pool.clear! unless @pool.nil?
    end
    
    def connected?
      @connected
    end
    
    def reap_connections!
      @pool.reap! unless @pool.nil?
    end
    
    def wait_for_notify time=0
      @pool.with { |pg| pg.wait_for_notify time }
    end
    
    # no quotes
    # Should be called when connected.
    # It defaults to a less secure method.
    def escape s=""
      raise Mystic::Postgres::Error, "Database connection required to escape strings." unless connected?
      @pool.with { |pg| pg.escape_string s.to_s }
    end
    
    # single quotes
    def quote s=""
      raise Mystic::Postgres::Error, "Database connection required to escape strings." unless connected?
      @pool.with { |pg| pg.escape_literal s.to_s }
    end
    
    # double quotes
    def dblquote s=""
      raise Mystic::Postgres::Error, "Database connection required to escape strings." unless connected?
      @pool.with { |pg| pg.escape_identifier s.to_s }
    end
    
    def execute sql=""
      raise Mystic::Postgres::Error, "Database connection required to execute SQL." unless connected?
      @pool.with { |pg| pg.execute sql }
    end
  end
end
