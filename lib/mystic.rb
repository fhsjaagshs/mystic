#!/usr/bin/env ruby

require "mystic/mystic-migration"
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
		adapter = "postgres" if adapter == "postgresql" # our adapter is called postgres not postgresql
		
		# setup our adapter
		require "mystic/adapters/" + adapter
		
		adapter_class = adapter_name.capitalize + "Adapter"
		@@adapter = Object.const_get(adapter_class).new
		@@adapter.pool_size = db_conf.delete("pool").to_i
		@@adapter.pool_timeout = db_conf.delete("timeout").to_i
		@@adapter.connect(opts)
	end

  def self.execute(sql)
    adptr = self.adapter
    adptr.nil? ? nil : adptr.exec(sql)
  end
  
  def self.sanitize(string)
    adptr = self.adapter
    adptr.nil? ? nil : adptr.sanitize(string)
  end
end