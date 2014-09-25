#!/usr/bin/env ruby

module Mystic
	MysticError = Class.new StandardError
  SQLError = Class.new StandardError
	RootError = Class.new StandardError
	EnvironmentError = Class.new StandardError
	AdapterError = Class.new StandardError
  ConnectionError = Class.new StandardError
	CLIError = Class.new StandardError
	MIG_REGEX = /^(?<num>\d+)_(?<name>[a-zA-Z]+)\.rb$/ # example: 1_MigrationClassName.rb
	JSON_COL = "mystic_return_json89788".freeze
  VALID_ADAPTERS = [
    "postgres",
    "postgis"
  ].freeze
  
	PG_CONNECT_FIELDS = [
		:host,
		:hostaddr,
		:port,
		:dbname,
		:user,
		:password,
		:connect_timeout,
		:options,
		:tty,
		:sslmode,
		:krbsrvname,
		:gsslib
	].freeze
  
	INDEX_TYPES = [
    :btree,
		:hash,
		:gist,
		:spgist,
		:gin
	].freeze
end