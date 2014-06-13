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