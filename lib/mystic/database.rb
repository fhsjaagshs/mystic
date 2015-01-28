#!/usr/bin/env ruby

require_relative "./access_stack"
require "mystic/postgres"

module Mystic
  class << self
    def connect dbconf=nil, poolconf=nil
      disconnect if connected?
      dbconf ||= config.database
      poolconf ||= config.pool
      ENV["DATABASE_URL"] = config.database_url dbconf
      @pool = AccessStack.new poolconf
      @pool.validate { |pg| !pg.nil? && pg.valid? }
      @pool.create { Mystic::Postgres.new (dbconf || config.database) }
      @pool.destroy { |pg| pg.disconnect! }
    end

    def disconnect
      @pool.clear! unless @pool.nil?
    end
    
    def connected?
      !@pool.nil? && @pool.empty?
    end
    
    def reap_connections!
      @pool.reap! unless @pool.nil?
    end
    
    def wait_for_notify time=0
      @pool.with { |pg| pg.wait_for_notify time }
    end
    
    # no quotes
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
