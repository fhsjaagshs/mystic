#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "pg"
require "mystic/model"

# Mystic adapter for Postgres, includes PostGIS

def parse_array(obj)
	return obj[1..-2].split(',').map(&method(:parse_array)) if obj.is_a?(String) && obj[0] == "{" && obj[-1] == "}"
	obj
end

module Mystic
	class PostgresAdapter < Mystic::Adapter
		execute do |inst, sql|
			res = inst.exec(sql)
			ret = res[0][Mystic::Model::JSON_COL] if res.num_tuples == 1
			return ret unless ret.nil?
			res.nfields.times.map { |i| res[i] }
		end
  
		sanitize do |inst, str|
			inst.escape_string(string)
		end
  
		connect do |opts|
			PG.connect(opts)
		end
  
		disconnect do |inst|
			inst.close
		end
	  
		sql do |obj|
			sql = []
      
			case obj
			when SQL::Table
        unless obj.columns.empty?
          sql << "CREATE TABLE #{obj.name} (#{obj.columns.map(&:to_sql)*","});" if obj.is_create == true
          sql << "ALTER TABLE #{obj.name} #{obj.columns.map{|c| "ADD COLUMN #{c.to_sql}" }*', '}" if obj.is_create == false
        end
				sql << obj.indeces.map(&:to_sql)*";" unless obj.indeces.empty?
        sql << obj.operations.map(&:to_sql)*";" unless obj.operations.empty?
			when SQL::Index
				sql << "CREATE"
				sql << "UNIQUE" if obj.unique
				sql << "INDEX"
			  sql << obj.name unless obj.name.nil?
			  sql << "ON"
				sql << obj.tblname
				sql << "USING #{obj.type}" if obj.type
				sql << "(#{obj.columns.map { |h| h[:name].to_s + " " + h[:order].to_s } * ","})" if obj.columns.is_a?(Hash)
				sql << "WITH (#{obj.with.sql_stringify("=")})" if obj.with
				sql << "TABLESPACE #{obj.tablespace}" if obj.tablespace
			when SQL::Column
				sql << obj.name.to_s
				sql << obj.kind.to_s.downcase
				sql << "(#{obj.size})" if obj.size && obj.geospatial? == false
				sql << "(#{obj.geom_kind}, #{obj.geom_srid})" if obj.geospatial?
        sql << obj.constraints[:null] ? "NULL" : "NOT NULL" if obj.constraints.member?(:null)
				sql << "UNIQUE" if obj.constraints[:unique]
				sql << "PRIMARY KEY" if obj.constraints[:primary_key]
				sql << "REFERENCES " + obj.constraints[:references] if obj.constraints.member?(:references)
				sql << "DEFAULT " + obj.constraints[:default] if obj.constraints.member?(:default)
			when SQL::CheckConstraint
				sql << "CONSTRAINT #{obj.name} CHECK(#{obj.conditions})"
			when SQL::Constraint
				sql << obj.sqlize
			when SQL::Operation
				case obj.kind
				when :drop_index
					sql << "DROP INDEX #{obj.index_name}"
				when :drop_table
					sql << "DROP TABLE #{obj.table_name}"
				when :create_view
					sql << "CREATE VIEW #{obj.view_name} AS #{obj.view_sql}"
				when :drop_view
					sql << "DROP VIEW #{obj.view_name}"
				when :rename_column
					sql << "ALTER TABLE #{obj.table_name} RENAME COLUMN #{obj.old_col_name} TO #{obj.new_col_name}"
				when :rename_table
					sql << "ALTER TABLE #{obj.old_name} RENAME TO #{obj.new_name}"
				when :drop_columns
					sql << "ALTER TABLE #{obj.table_name} DROP COLUMN #{obj.column_names*","}"
        when :create_extension
          sql << "CREATE EXTENSION \"#{obj.name}\""
        when :drop_extension
          sql << "DROP EXTENSION \"#{obj.name}\""
        end
			end
      
			sql*" "
		end
	end
end