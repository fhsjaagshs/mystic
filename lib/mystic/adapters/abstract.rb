#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "mystic/sql"

#
# This adapter is designed to hold
# basic, spec-adherent SQL generation
#	so adapters can be more DRY
#

module Mystic
	class Adapter
		
		json_supported { false }
		
		table do |obj|
			sql = []
      sql.push "CREATE TABLE #{obj.name} (#{obj.columns.map(&:to_sql)*","})" if obj.create?
      sql.push "ALTER TABLE #{obj.name} #{obj.columns.map{|c| "ADD COLUMN #{c.to_sql}" }*', '}" unless obj.create?
			sql.push *(obj.indeces.map(&:to_sql)) unless obj.indeces.empty?
	    sql.push *(obj.operations.map(&:to_sql)) unless obj.operations.empty?
			sql*"; "
		end
		
		column do |obj|
			sql = []
			sql << obj.name
			sql << obj.kind.downcase
			sql << "(#{obj.size})" if obj.size && !obj.size.empty? && !obj.geospatial?
			sql << "(#{obj.geom_kind}, #{obj.geom_srid})" if obj.geospatial?
      sql << (obj.constraints[:null] ? "NULL" : "NOT NULL") if obj.constraints.member?(:null)
			sql << "UNIQUE" if obj.constraints[:unique]
			sql << "PRIMARY KEY" if obj.constraints[:primary_key]
			sql << "REFERENCES " + obj.constraints[:references] if obj.constraints.member?(:references)
			sql << "DEFAULT " + obj.constraints[:default] if obj.constraints.member?(:default)
			sql << "CHECK(#{obj.constraints[:check]})" if obj.constraints.member?(:check)
			sql*" "
		end
		
		index do |index|
			sql = []
			sql << "CREATE"
			sql << "UNIQUE" if index.unique
			sql << "INDEX"
		  sql << index.name if index.name
		  sql << "ON"
			sql << index.table_name
			sql << "(#{index.columns.map(&:to_s).join(',')})"
			sql*" "
		end
		
		#
		## Operations
		#
		
		drop_columns do |obj|
			"ALTER TABLE #{obj.table_name} #{obj.column_names.map{|c| "DROP COLUMN #{c.to_s}" }*', '}"
		end
		
		rename_column do |obj|
			"ALTER TABLE #{obj.table_name} RENAME COLUMN #{obj.old_name} TO #{obj.new_name}"
		end
		
		create_view do |obj|
			"CREATE VIEW #{obj.name} AS #{obj.sql}"
		end
		
		drop_view do |obj|
			"DROP VIEW #{obj.name}"
		end
		
		drop_table do |obj|
			"DROP TABLE #{obj.table_name} #{obj.cascade? ? "CASCADE" : "RESTRICT" }"
		end
		
		rename_table do |obj|
			"ALTER TABLE #{obj.old_name} RENAME TO #{obj.new_name}"
		end
		
		#
		## Transaction Operations
		#
		
		start_transaction { "BEGIN" }
		commit_transaction { "COMMIT" }
		rollback_transaction { "ROLLBACK" }
	end
end