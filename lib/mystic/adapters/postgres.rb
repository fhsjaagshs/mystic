#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "pg"
require "mystic/model"
require "mystic/sql"

# Mystic adapter for Postgres, includes PostGIS

# TODO: Make this pretty
def parse_array(obj)
	obj = obj[1..-2].split('},{').map { |str|
		return str.split(",") if str[0] != "{" && str[-1] != "}"
		str = "{" + str if str[0] != "{" && str[-1] == "}"
		str = str + "}" if str[-1] != "}" && str[0] == "{"
		parse_array(str)
	} if obj.is_a?(String) && obj[0] == "{" && obj[-1] == "}"
	obj
end

def parse_res(res)
	res.ntuples.times.map do |i|
		Hash[res.nfields.times.map{ |j|
			v =
			case res.ftype(j)
			when 16 # boolean
				["TRUE","t","true","y","yes","on","1"].include?(res.getvalue(i, j))
			else
				parse_array(res.getvalue(i, j)) # Parses array the string contains brackets on the start and end
			end
			[res.fname(j), v]
		}]
	end
end

module Mystic
	class PostgresAdapter < Mystic::Adapter
		execute do |inst, sql|
			res = inst.exec(sql)
			ret = res[0][Mystic::Model::JSON_COL] if res.ntuples == 1 && res.nfields == 1 && [114,199].include?(res.ftype(0)) # 114 is the OID of the json datatype, 119 corresponds to _json
			ret ||= parse_res(res)
			ret
		end
  
		sanitize do |inst, str|
			inst.escape_string(string)
		end
  
		connect do |opts|
			pg = PG.connect(opts)
			pg.set_notice_processor {} # { |message| puts "mystic: " + message[9..-1].capitalize} # TODO: Save notices to Mystic's notice queue 
			pg
		end
  
		disconnect do |inst|
			inst.close
		end
	  
		sql do |obj|
			sql = []
      
			case obj
			when SQL::Table
        unless obj.columns.empty?
          sql << "CREATE TABLE #{obj.name} (#{obj.columns.map(&:to_sql)*","});" if obj.create? == true
          sql << "ALTER TABLE #{obj.name} #{obj.columns.map{|c| "ADD COLUMN #{c.to_sql}" }*', '};" if obj.create? == false
        end
				sql << obj.indeces.map(&:to_sql)*";" + ";" unless obj.indeces.empty?
        sql << obj.operations.map(&:to_sql)*";" + ";" unless obj.operations.empty?
			when SQL::Index
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
			when SQL::Column
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
					sql << "ALTER TABLE IF EXISTS #{obj.old_name} RENAME TO #{obj.new_name}"
				when :drop_columns
					sql << "ALTER TABLE #{obj.table_name} #{obj.column_names.map{|c| "DROP COLUMN #{c.to_s}" }*', '}"
        when :create_extension
          sql << "CREATE EXTENSION \"#{obj.name}\""
        when :drop_extension
          sql << "DROP EXTENSION \"#{obj.name}\""
        end
				obj.callback.call unless obj.callback.nil?
			end
			
			sql*" "
		end
	end
end