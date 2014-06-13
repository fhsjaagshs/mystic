#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "mysql2"

# TODO:
# 1. Implement geometry
# 2. Check syntax, this is adapted from the Postgres adapter

module Mystic
	class MysqlAdapter < Mystic::Adapter
	  execute do |inst, sql|
			inst.query(sql).to_a
	  end
  
	  sanitize do |inst, str|
	    inst.escape(string)
	  end
  
	  connect do |opts|
	    Mysql2::Client.new(opts)
	  end
  
	  disconnect do |inst|
	    inst.close
	  end
		
		drop_index do |obj|
			"DROP INDEX #{obj.name} ON #{obj.table_name}"
		end
	end
end