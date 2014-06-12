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
	  
		operation do |obj|
			sql = []
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
      end
			obj.callback.call unless obj.callback.nil?
			sql*" "
		end
	end
end