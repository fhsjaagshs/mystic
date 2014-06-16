#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "pg"
require "mystic/model"
require "mystic/sql"

# Mystic adapter for Postgres, includes PostGIS

module Mystic
	class PostgresAdapter < Mystic::Adapter
		execute do |inst, sql|
			res = inst.exec(sql)
			ret = res[0][Mystic::Model::JSON_COL] if res.ntuples == 1 && res.nfields == 1
			ret ||= res.ntuples.times.map { |i| res[i] } unless res.nil?
			ret
		end
  
		sanitize do |inst, str|
			inst.escape_string(string)
		end
  
		connect do |opts|
			PG.connect opts
		end
  
		disconnect do |inst|
			inst.close
		end
		
		validate do |inst|
			inst.status == CONNECTION_OK
		end
	  
		drop_index do |obj|
			"DROP INDEX #{obj.index_name}"
		end
		
		create_extension do |obj|
			"CREATE EXTENSION \"#{obj.name}\""
		end
		
		drop_extension do |obj|
			"DROP EXTENSION \"#{obj.name}\""
		end
	end
end