#!/usr/bin/env ruby

require "yaml"
require "erb"
require "pg"
require_relative "./postgres"

module Mystic
  ConnectionError = Class.new StandardError
  EnvironmentError = Class.new StandardError
  UnsuppordedError = StandardError.with_message "Mystic only supports Postgres and Postgis."
  
  "host", "hostaddr", "port", "dbname", "user", "password", "connect_timeout", "client_encoding", "options", "sslmode"
  
  VALID_ADAPTERS = [
    "postgres",
    "postgis"
  ].freeze
  
  VALID_ENVIRONMENTS = [
    
  ]
  
  VALID_ENV_FIELDS = [
    # Things like 
    # username
    # database
    # encoding
    # other shit
  ]
  
  class << self
    def db_yml
      if @db_yml.nil?
        # Heroku uses ERB cuz rails uses it errwhere
        dy = YAML.load(ERB.new(root.join("config","database.yml").read).result)
        puts dy.inspect
        # Clean up the config
        @db_yml = Hash[dy.select { |k,v| VALID_ADAPTERS.include? v["adapter"] }.map {|env,hash| 
          hash[:dbname] = hash.delete :database # PG accepts differently named params
          hash[:user] = hash.delete :username # PG accepts differently named params
          [env, hash.subhash(*Mystic::Postgres::CONNECT_FIELDS).symbolize]
        }]
      end
      @db_yml
    end
    
    def manual_conn conf={}
			@pool = AccessStack.new(
				:size => conf[:pool] || 5,
				:timeout => conf[:timeout] || 30,
				:expires => conf[:expires],
				:create => lambda { Mystic::Postgres.new conf },
        :destroy => lambda { |pg| pg.disconnect! },
        :validate => lambda { |pg| pg != nil && pg.valid? }
			)
      @connected = true
    end
    
    def env
      ENV["RACK_ENV"] || DOTENV["RACK_ENV"] || "development"
    end
    
    def env= new_env
      disconnect
      puts db_yml
      ENV["RACK_ENV"] = new_env.to_s
			raise EnvironmentError, "Environment '#{@env}' doesn't exist." unless db_yml.key? env
			manual_conn db_yml[env]
      @env
    end
    
    alias_method :connect, :env=

		def disconnect
      @connected = false
			@pool.empty! unless @pool.nil?
		end
    
    def connected?
      @pool.reap!
      [!@pool.empty?, @connected].any?
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
      raise ConnectionError, "Not connected to Postgres." unless connected?
      begin
  			res = @pool.with { |pg| pg.exec sql.terminate } 
  			v = res[0][Mystic::JSON_COL] if res.ntuples == 1 && res.nfields == 1
  			v ||= res.ntuples.times.map { |i| res[i] } unless res.nil? || res.ntuples == 0
  			v ||= []
  			v
      rescue StandardError=>e
        if e.class.to_s.split("::").first != "PG"
          raise e
          return []
        end
        raise(Mystic::SQL::Error, e.message)
        return []
      end
    end
  end
end