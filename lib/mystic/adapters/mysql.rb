#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "mysql2"

# TODO:
# 1. Implement geometry

module Mystic
	class MysqlAdapter < Mystic::Adapter
		ALGORITHMS = [:default, :inplace, :copy]
		LOCKS = [:default, :none, :shared, :exclusive]
		
		connect { |opts| Mysql2::client.new opts }
		disconnect { |mysql| mysql.close }
		validate { |mysql| mysql.ping }
		execute { |mysql, sql| mysql.query(sql).to_a }
		sanitize { |mysql, str| mysql.escape str }
		
		drop_index do |index|
			"DROP INDEX #{index.name} ON #{index.table_name}"
		end
		
		index do |index|
			sql = []
			sql << "CREATE"
			sql << "UNIQUE" if index.unique
			sql << "INDEX"
		  sql << index.name if index.name
		  sql << "ON"
			sql << index.table_name
			sql << "USING #{obj.type.to_s.capitalize}" if index.type
			sql << "(#{index.columns.map(&:to_s).join ',' })"
			sql << "COMMENT #{index.comment.truncate 1024}" if index.comment
			sql << "ALGORITHM #{index.algorithm.to_s.upcase}" if !index.lock && ALGORITHMS.include? index.algorithm
			sql << "LOCK #{index.lock.to_s.upcase}" if !index.algorithm && LOCKS.include? index.lock
			sql*" "
		end
	end
end