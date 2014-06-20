#!/usr/bin/env ruby

require "pg"

# Mystic adapter for Postgres, includes PostGIS

module Mystic
	class PostgresAdapter < Mystic::Adapter
		INDEX_TYPES = [:btree, :hash, :gist, :spgist, :gin]
		FIELDS = [:host, :hostaddr, :port, :dbname, :user, :password, :connect_timeout, :options, :tty, :sslmode, :krbsrvname, :gsslib]
		
		connect { |opts| PG.connect opts.subhash(*FIELDS) }
		disconnect { |pg| pg.close }
		validate { |pg| pg.status == CONNECTION_OK }
		sanitize { |pg, str| pg.escape_string string }
		
		execute do |inst, sql|
			res = inst.exec sql
			ret = res[0][Mystic::Model::JSON_COL] if res.ntuples == 1 && res.nfields == 1
			ret ||= res.ntuples.times.map { |i| res[i] } unless res.nil?
			ret ||= []
			ret
		end
		
		drop_index do |index| 
			"DROP INDEX #{index.index_name}"
		end
		
		create_extension do |ext| 
			"CREATE EXTENSION \"#{ext.name}\""
		end
		
		drop_extension do |ext|
			"DROP EXTENSION \"#{ext.name}\"" 
		end
		
		index do |index|
			storage_params = index.opts.subhash :fillfactor,:buffering,:fastupdate
			
			sql = []
			sql << "CREATE"
			sql << "UNIQUE" if index.unique
			sql << "INDEX"
			sql << "CONCURENTLY" if index.concurrently
		  sql << index.name unless index.name.nil?
		  sql << "ON #{index.table_name}"
			sql << "USING #{index.type}" if INDEX_TYPES.include? index.type
			sql << "(#{index.columns.map(&:to_s).join ',' })"
			sql << "WITH (#{storage_params.sqlize})" unless storage_params.empty?
			sql << "TABLESPACE #{index.tablespace}" unless index.tablespace.nil?
			sql << "WHERE #{index.where}" unless index.nil?
			sql*' '
		end

		table do |table|
			sql = []
			
			if obj.create?
				sql << "CREATE TABLE #{table.name} (#{table.columns.map(&:to_sql)*","})"
				sql << "INHERITS " + table.inherits if table.inherits
				sql << "TABLESPACE " + table.tablespace if table.tablespace
			else
				sql << "ALTER TABLE #{table.name} #{table.columns.map{ |c| "ADD COLUMN #{c.to_sql}" }*', ' }"
			end
      
			sql.push *(table.indeces.map(&:to_sql)) unless table.indeces.empty?
	    sql.push *(table.operations.map(&:to_sql)) unless table.operations.empty?
			sql*"; "
		end
	end
end