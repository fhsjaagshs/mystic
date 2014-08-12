#!/usr/bin/env ruby

module Mystic
	MysticError = Class.new StandardError
	RootError = Class.new StandardError
	EnvironmentError = Class.new StandardError
	AdapterError = Class.new StandardError
	CLIError = Class.new StandardError
	MIG_REGEX = /^(?<num>\d+)_(?<name>[a-zA-Z]+)\.rb$/ # matches migration files (ex '1_MigrationClassName.rb')
	JSON_COL = "mystic_return_json89788"
end