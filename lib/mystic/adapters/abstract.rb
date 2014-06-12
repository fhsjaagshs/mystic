#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "mystic/sql"

#
# This adapter is designed to hold
# 'basic' SQL generation code so adapters
# can be more DRY
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
	end
end