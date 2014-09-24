#!/usr/bin/env ruby

require "yaml"
require "erb"
require "pathname"
require "densify"
require_relative "./mystic/extensions.rb"
require_relative "./mystic/sql.rb"
require_relative "./mystic/postgres.rb"
require_relative "./mystic/migration.rb"
require_relative "./mystic/model.rb"

module Mystic
	MysticError = Class.new StandardError
  SQLError = Class.new StandardError
	RootError = Class.new StandardError
	EnvironmentError = Class.new StandardError
	AdapterError = Class.new StandardError
  ConnectionError = Class.new StandardError
	CLIError = Class.new StandardError
	MIG_REGEX = /^(?<num>\d+)_(?<name>[a-zA-Z]+)\.rb$/ # example: 1_MigrationClassName.rb
	JSON_COL = "mystic_return_json89788"
  
	class << self
    attr_reader :postgres

    def db_yml
      if @db_yml.nil?
        # Heroku uses ERB cuz rails uses it errwhere
        yaml = ERB.new(root.join("config","database.yml").read).result
  			@db_yml = YAML.load yaml
      end
      @db_yml
    end
    
    def manual_conn conf={}
      @env = ENV["RACK_ENV"] || dotenv["RACK_ENV"] || "development"
      @postgres = Postgres.new conf
    end
    
    def env
      @env
    end
    
    def env= new_env
      @postgres.disconnect unless @postgres.nil?
      @postgres = nil
			@env = (new_env || ENV["RACK_ENV"] || dotenv["RACK_ENV"] || "development").to_s
			raise EnvironmentError, "Environment '#{@env}' doesn't exist." unless db_yml.key? @env
      
      conf = db_yml[@env].symbolize
      conf[:dbname] = conf.delete :database
      conf[:user] = conf.delete :username
      raise MysticError, "Mystic only supports Postgres." unless conf[:adapter] == "postgres" || conf[:adapter] == "postgis"
      
      @postgres = Postgres.new conf
      
      @env
    end
    
    alias_method :connect, :env=
    
    def root
      if @root.nil?
        r = Pathname.new Dir.pwd
        
        until r.join("config", "database.yml").file? do # exist? is implicit with file?
          raise RootError, "Could not find the project's root." if r.root?
          r = r.parent
        end

        @root = r
      end
      @root.dup
    end

		def disconnect
      postgres.disconnect
		end

		def execute sql=""
      raise ConnectionError, "Not connected to Postgres" unless postgres.connected?
			postgres.execute sql.terminate.densify
		end

		def escape str=""
			raise ConnectionError, "Not connected to Postgres" unless postgres.connected?
			postgres.escape str
    end
    
    def dotenv
      @dotenv ||= Hash[root.join(".env").read.split("\n").map { |l| l.strip.split "=", 2 }] rescue {}
    end
	end
end