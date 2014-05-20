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
  
	  sql do |obj|
	    sql = []
    
	    case obj
	    when SQL::Table
	      sql << "CREATE TABLE #{obj.name} (#{obj.columns.map(&:to_sql)*","});"
	      sql << obj.indeces.map(&:to_sql)*";" unless obj.indeces.empty?
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
	      sql << "(#{obj.size})" if obj.size
	      sql << "NOT NULL" if obj.constraints[:not_null]
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
	        sql << "DROP INDEX #{obj.index_name} ON #{obj.table_name}"
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
	      when :add_column
	        sql << "ALTER TABLE #{obj.table_name} ADD COLUMN #{obj.column.to_sql}"
	      end
	    end
    
	    sql*" "
	  end
	end
end