#!/usr/bin/env ruby

require "yaml"
require "erb"

module Mystic
  class << self
    def db_yml
      @db_yml ||= YAML.load(ERB.new(root.join("config","database.yml").read).result).symbolize # Heroku uses ERB cuz rails uses it errwhere
    end
    
    def manual_conn conf={}
			@pool = AccessStack.new(
				:size => conf[:pool] || 5,
				:timeout => conf[:timeout] || 30,
				:expires => conf[:expires],
				:create => lambda {
          pg = PG.connect conf.subhash(*PG_CONNECT_FIELDS)
          pg.set_notice_receiver { |r| }
          pg
        },
        :destroy => lambda { |pg| pg.close },
        :validate => lambda { |pg| pg != nil && pg.status == CONNECTION_OK }
			)
      @connected = true
    end
    
    def env
      ENV["RACK_ENV"] || DOTENV["RACK_ENV"] || "development"
    end
    
    def env= new_env
      disconnect
      ENV["RACK_ENV"] = new_env.to_s
			raise EnvironmentError, "Environment '#{@env}' doesn't exist." unless db_yml.key? env
      
      conf = db_yml[env]
      conf[:dbname] = conf.delete :database
      conf[:user] = conf.delete :username
      raise MysticError, "Mystic only supports Postgres." unless VALID_ADAPTERS.include? conf[:adapter]

			manual_conn conf
      
      @env
    end
    
    alias_method :connect, :env=

		def disconnect
      @connected = false
			@pool.empty!
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
			res = @pool.with { |pg| pg.exec sql.terminate }
			v = res[0][Mystic::JSON_COL] if res.ntuples == 1 && res.nfields == 1
			v ||= res.ntuples.times.map { |i| res[i] } unless res.nil? || res.ntuples == 0
			v ||= []
			v
    end
  end
end