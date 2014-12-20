#!/usr/bin/env ruby

require "uri"
require "access_stack"
require_relative "./postgres"
require_relative "./config"

module Mystic
  EnvironmentError = Class.new StandardError

  class << self
    def manual_conn dbconf={}, poolconf={}
      @pool = AccessStack.new poolconf
      @pool.create { @connected = true; Mystic::Postgres.new dbconf }
      @pool.destroy { |pg| pg.disconnect! }
      @pool.validate { |pg| pg != nil && pg.valid? }
      @connected = true
    end
    
    def env
      ENV["RACK_ENV"] || DOTENV["RACK_ENV"] || ENV["RAILS_ENV"] || DOTENV["RAILS_ENV"] || "development"
    end
    
    def env= new_env
      raise EnvironmentError, "Environment '#{new_env}' doesn't exist." unless db_yml.key? new_env
      disconnect
      ENV["RACK_ENV"] = new_env.to_s
      ENV["DATABASE_URL"] = database_url
      manual_conn config, pool_config
      new_env
    end
    
    alias_method :connect, :env=

    def disconnect
      @connected = false
      @pool.clear! unless @pool.nil?
    end
    
    def connected?
      @connected
    end
    
    def reap_connections!
      @pool.reap!
    end
    
    # no quotes
    # Should be called when connected.
    # It defaults to a less secure method.
    def escape s=""
      @pool.with { |pg| pg.escape_string s.to_s }
    end
    
    # single quotes
    def quote s=""
      @pool.with { |pg| pg.escape_literal s.to_s }
    end
    
    # double quotes
    def dblquote s=""
      @pool.with { |pg| pg.escape_identifier s.to_s }
    end
    
    def execute sql=""
      @pool.with { |pg| pg.execute sql }
    end
  end
end
