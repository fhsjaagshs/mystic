#!/usr/bin/env ruby

require "mystic/migration"
require "mystic/extensions"
require "mystic/sql"
require "mystic/adapter"
require "mystic/model"

module Mystic
	MysticError = Class.new(StandardError)
	
	def self.adapter
		@@adapter
	end
  
	def self.load_config(env="")
		# Load database.yml
		env = env.to_s
		path = File.join(File.app_root, "/config/database.yml")
		db_conf = YAML.load_file(path)
		raise MysticError, "Invalid database.yml config." if db_conf.member?(env)
		
		# get adapter name
		adapter = db_conf.delete("adapter").to_s.downcase
		adapter = "postgres" if adapter == "postgresql" || adapter == "postgis" # Mystic's adapter is 'postgres' and supports PostGIS
		
		# setup our adapter
		require "mystic/adapters/" + adapter
		
		adapter_class = adapter_name.capitalize + "Adapter"
		@@adapter = Object.const_get(adapter_class).new
		@@adapter.pool_size = db_conf.delete("pool").to_i
		@@adapter.pool_timeout = db_conf.delete("timeout").to_i
		@@adapter.connect(db_conf)
	end
	
	def self.disconnect
		@@adapter.disconnect
	end

  def self.execute(sql)
		return [] if @@adapter.nil?
    @@adapter.exec(sql)
  end
  
  def self.sanitize(str)
		return str if @@adapter.nil?
    @@adapter.sanitize(str)
  end
end