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
		table do |obj|
			sql = []
	    unless obj.columns.empty?
	      sql << "CREATE TABLE #{obj.name} (#{obj.columns.map(&:to_sql)*","});" if obj.create? == true
	      sql << "ALTER TABLE #{obj.name} #{obj.columns.map{|c| "ADD COLUMN #{c.to_sql}" }*', '};" if obj.create? == false
	    end
			sql << obj.indeces.map(&:to_sql)*";" + ";" unless obj.indeces.empty?
	    sql << obj.operations.map(&:to_sql)*";" + ";" unless obj.operations.empty?
			sql*" "
		end
		
		#
		## Operations
		#
		
		drop_columns do |obj|
			"ALTER TABLE #{obj.table_name} #{obj.column_names.map{|c| "DROP COLUMN #{c.to_s}" }*', '}"
		end
		
		rename_column do |obj|
			"ALTER TABLE IF EXISTS #{obj.old_name} RENAME TO #{obj.new_name}"
		end
		
		create_view do |obj|
			"CREATE VIEW #{obj.name} AS #{obj.sql}"
		end
		
		drop_view do |obj|
			"DROP VIEW #{obj.name}"
		end
		
		drop_table do |obj|
			"DROP TABLE #{obj.table_name}"
		end
		
		rename_table do |obj|
			"ALTER TABLE #{obj.old_name} RENAME TO #{obj.new_name}"
		end
	end
end