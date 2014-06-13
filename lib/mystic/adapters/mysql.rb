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
  
		index do |obj|
			sql = []
			sql << "CREATE"
			sql << "UNIQUE" if obj.unique
			sql << "INDEX"
		  sql << obj.name unless obj.name.nil?
		  sql << "ON"
			sql << obj.tblname
			sql << "USING #{obj.type}" if obj.type
			sql << "(#{obj.columns.map(&:to_s)*","})" if obj.columns.is_a?(Array) && obj.columns
			sql << "WITH (#{obj.with.sqlize})" if obj.with
			sql << "TABLESPACE #{obj.tablespace}" if obj.tablespace
			sql*" "
		end
		
		drop_index do |obj|
			"DROP INDEX #{obj.name} ON #{obj.table_name}"
		end
	end
end