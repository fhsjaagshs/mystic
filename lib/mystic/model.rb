#!/usr/bin/env ruby

module Mystic
  class Model
    def self.table_name
      to_s.downcase
    end
		
		def self.visible_cols
			["*"]
		end
    
    def self.select_sql(opts={})
      count = opts.delete(:count) || opts.delete("count") || 0
			return_json = (opts.delete(:return_json) || opts.delete("return_json")) && Mystic.adapter.name == "postgres"
      pairs = opts.sqlize
			
			return "" if opts.empty?
      
      sql = "SELECT #{visible_cols*','} FROM #{table_name}"
      sql << " WHERE #{pairs*' AND '}" unless pairs.empty?
      sql << " LIMIT #{count.to_i.to_s}" if count > 0
			
			sql = "SELECT row_to_json(row) as json FROM (#{sql}) row;" if return_json
			
      sql
    end
    
    def self.function_sql(funcname, *params)
			"SELECT " + funcname.to_s + "(" + params.map{ |param| "'" + param.to_s.sanitize + "'" }*',' + ");"
    end
    
    def self.update_sql(where={}, set={}, opts={})
			return_rows = opts[:return_rows] || opts["return_rows"]
			return_json = (opts[:return_json] || opts["return_json"]) && Mystic.adapter.name == "postgres"
			return_rows = true if return_json
			
      where_pairs = where.sqlize
      set_pairs = set.sqlize
			
			return "" if where_pairs.empty? && set_pairs.empty?
			
      sql = "UPDATE " + table_name + " SET " + set_pairs*',' + " WHERE " + where_pairs*' AND ' 
			sql << " RETURNING " + visible_cols*',' if return_rows
			
			sql = "WITH res AS (#{sql}) SELECT row_to_json(res) FROM res" if return_json
			
			sql
    end
    
    def self.insert_sql(opts={})
			return_rows = opts.delete(:return_rows) || opts.delete("return_rows")
			return_json = (opts.delete(:return_json) || opts.delete("return_json")) && Mystic.adapter.name == "postgres"
			return_rows = true if return_json
			
			return "" if opts.empty?
			
      sql = "INSERT INTO " + table_name + "(" + opts.keys*',' + ") VALUES (" + opts.values.map { |value| "'" + value.to_s.sanitize + "'" }*',' + ")"
			sql << " RETURNING " + visible_cols*',' if return_rows
			
			sql = "WITH res AS (#{sql}) SELECT row_to_json(res) FROM res" if return_json
			
			sql
    end
    
    def self.delete_sql(opts={})
			return_rows = opts.delete(:return_rows) || opts.delete("return_rows")
			return_json = (opts.delete(:return_json) || opts.delete("return_json")) && Mystic.adapter.name == "postgres"
			return_rows = true if return_json
			
			return "" if opts.empty?
			
      sql = "DELETE FROM " + table_name + " WHERE " + opts.sqlize*' AND ' + " RETURNING " + + visible_cols*','
			sql << " RETURNING " + visible_cols*',' if return_rows
			
			sql = "WITH res AS (#{sql}) SELECT row_to_json(res) FROM res" if return_json
			
			sql
    end
  end
end