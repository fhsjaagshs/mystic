#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "pg"
require "mystic/model"
require "mystic/sql"

# Mystic adapter for Postgres, includes PostGIS

module Mystic
	module PGHelpers
		def parse_array(obj)
			obj = obj[1..-2].split('},{').map { |s|
				return str.split(",") if s[0] != "{" && s[-1] != "}"
				s = s + "}" unless str[-1] == "}"
				s = "{" + s unless s[0] == "{"
				parse_array(s)
			} if obj.match /^\{+.*\}+$/ rescue false
			obj
		end

		def parse_res(res)
			res.ntuples.times.map do |i|
				Hash[res.nfields.times.map{ |j|
					v = nil
					if (Mystic.config[:convert_types] || false) == true
						v =
						# These are Postgres OIDs
						case res.ftype(j)
						when 16 # boolean
							["TRUE","t","true","y","yes","on","1"].include?(res.getvalue(i, j))
						else
							parse_array(res.getvalue(i, j)) # Parses array the string contains brackets on the start and end
						end
					else
						v = res.getvalue(i, j)
					end
			
					[res.fname(j), v]
				}].rehash
			end
		end
	end
end

module Mystic
	class PostgresAdapter < Mystic::Adapter
		execute do |inst, sql|
			res = inst.exec(sql)
			ret = res[0][Mystic::Model::JSON_COL] if res.ntuples == 1 && res.nfields == 1 && [114,199].include?(res.ftype(0)) # 114 is the OID of the json datatype, 119 corresponds to _json
			ret ||= Mystic::PGHelpers.parse_res(res)
			ret
		end
  
		sanitize do |inst, str|
			inst.escape_string(string)
		end
  
		connect do |opts|
			pg = PG.connect(opts)
			pg.set_notice_processor {} # TODO: Save notices to a notice queue
			pg
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
		
		column do |obj|
			sql = []
			sql << obj.name.to_s
			sql << obj.kind.to_s.downcase
			sql << "(#{obj.size})" if obj.size && !obj.size.empty? && obj.geospatial? == false
			sql << "(#{obj.geom_kind}, #{obj.geom_srid})" if obj.geospatial?
      sql << obj.constraints[:null] ? "NULL" : "NOT NULL" if obj.constraints.member?(:null)
			sql << "UNIQUE" if obj.constraints[:unique]
			sql << "PRIMARY KEY" if obj.constraints[:primary_key]
			sql << "REFERENCES " + obj.constraints[:references] if obj.constraints.member?(:references)
			sql << "DEFAULT " + obj.constraints[:default] if obj.constraints.member?(:default)
			sql << "CHECK(#{obj.constraints[:check]})" if obj.constraints.member?(:check)
			sql*" "
		end
		
		#
		## Operations
		#
	  
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