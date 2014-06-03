#!/usr/bin/env ruby

require "mystic"

module Mystic
  class Model
    JSON_COL = "mystic_return_json"
    
    def self.table_name
      to_s.downcase
    end
		
		def self.visible_cols
			["*"]
		end
    
    def self.function_sql(funcname, *params)
			"SELECT " + funcname.to_s + "(" + fnc_parameterize(params)*',' + ");"
    end
    
    def self.select_sql(params={}, opts={})
      count = opts[:count] || opts["count"] || 0
			return_json = (opts[:return_json] || opt["return_json"]) && Mystic.adapter.name == "postgres"
      pairs = params.sqlize
			
      sql = "SELECT #{visible_cols*','} FROM #{table_name}"
      sql << " WHERE #{pairs*' AND '}" unless pairs.empty?
      sql << " LIMIT #{count.to_i.to_s}" if count > 0''
      
			sql = "SELECT row_to_json(res) as #{JSON_COL} FROM (#{sql}) res;" if return_json && count == 1
      sql = "SELECT array_to_json(array_agg(row_to_json(res))) as #{JSON_COL} from (#{sql}) res" if return_json && count != 1
			
      sql
    end
    
    def self.update_sql(where={}, set={}, opts={})
			return_rows = opts[:return_rows] || opts["return_rows"]
			return_json = (opts[:return_json] || opts["return_json"]) && Mystic.adapter.name == "postgres"
			return_rows = true if return_json
			
      return "" if where.empty?
      return "" if set.empty?
      
      where_pairs = where.sqlize
      set_pairs = set.sqlize
			
      sql = "UPDATE " + table_name + " SET " + set_pairs*',' + " WHERE " + where_pairs*' AND ' 
			sql << " RETURNING " + visible_cols*',' if return_rows
			
			sql = "WITH res as (#{sql}) SELECT array_to_json(array_agg(row_to_json(res))) as #{JSON_COL} FROM res" if return_json
			
			sql
    end
    
    def self.insert_sql(params={}, opts={})
			return "" if params.empty?
      
			return_rows = opts[:return_rows] || opts["return_rows"]
			return_json = (opts[:return_json] || opts["return_json"]) && Mystic.adapter.name == "postgres"
			return_rows = true if return_json
			
      sql = "INSERT INTO " + table_napme + "(" + params.keys*',' + ") VALUES (" + params.values.map { |value| "'" + value.to_s.sanitize + "'" }*',' + ")"
			sql << " RETURNING " + visible_cols*',' if return_rows
			
			sql = "WITH res as (#{sql}) SELECT row_to_json(res) as #{JSON_COL} FROM res" if return_json
      
			sql
    end
    
    def self.delete_sql(params={}, opts={})
      return "" if params.empty?
      
			return_rows = opts[:return_rows] || opts["return_rows"]
			return_json = (opts[:return_json] || opts["return_json"]) && Mystic.adapter.name == "postgres"
			return_rows = true if return_json
			
      sql = "DELETE FROM " + table_name + " WHERE " + opts.sqlize*' AND ' + " RETURNING " + + visible_cols*','
			sql << " RETURNING " + visible_cols*',' if return_rows
			
			sql = "WITH res as (#{sql}) SELECT array_to_json(array_agg(row_to_json(res))) as #{JSON_COL} FROM res" if return_json
      
			sql
    end
    
    def self.select(params={}, opts={})
      sql = self.select_sql(params,opts)
      Mystic.execute(sql)
    end
    
    def self.fetch(params={}, opts={})
      res = self.select(params,opts.merge({:count => 1}))
			return res if res.is_a?(String)
			res.first
    end
    
    def self.create(params={}, opts={})
      sql = self.insert_sql(params,opts)
      res = Mystic.execute(sql)
			return res.first if res.is_a?(Array)
			res
    end
    
    def self.update(where={}, set={}, opts={})
      sql = self.update_sql(where,set,opts.merge({ :return_rows => true }))
      Mystic.execute(sql)
    end
    
    def self.delete(params={}, opts={})
      sql = self.delete_sql(params,opts)
			Mystic.execute(sql)
    end
    
    private
    
    def fnc_parameterize(params)
      params.map do |param| 
        case param
        when String
          "'" + param.to_s.sanitize + "'" 
        when Integer, Float
          param.to_s.sanitize
        when Array, Hash
          # TODO: Turn into SQL params
        else
          nil
        end
      end
    end
  end
end