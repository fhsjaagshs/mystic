#!/usr/bin/env ruby

require "mystic"

module Mystic
  class Model
    JSON_COL = "mystic_return_json89788"
    
    def self.table_name
      to_s.downcase
    end
		
		def self.visible_cols
			["*"]
		end
		
		def self.wrapper_sql(sql="SELECT 1",return_rows=true,return_json=false)
			return_rows = true if return_json
			op = sql.split(" ",2)[0]
			
			s = []
			s << "WITH res as (" if return_json
			s << sql
			s << "RETURNING #{visible_cols*','}" if return_rows
			s << ") SELECT" if return_json
			s << "row_to_json(res)" if op == "INSERT"
			s << "array_to_json(array_agg(row_to_json(res)))" unless op == "INSERT"
			s << "as #{JSON_COL} FROM res" if return_json
			s*' '
		end
    
    def self.function_sql(funcname, *params)
			"SELECT " + funcname.to_s + "(" + fnc_parameterize(params)*',' + ");"
    end
    
    def self.select_sql(params={}, opts={})
			opts.symbolize!
      count = opts[:count] || 0
			return_json = opts[:return_json] && Mystic.adapter.name == "postgres"
			
			sql = []
			sql << "SELECT row_to_json(res) as #{JSON_COL} FROM (" if return_json && count == 1
      sql << "SELECT array_to_json(array_agg(row_to_json(res))) as #{JSON_COL} from (" if return_json && count != 1
			sql << "SELECT #{visible_cols*','} FROM #{table_name}"
			sql << "WHERE #{params.sqlize*' AND '}" unless pairs.empty?
			sql << "LIMIT #{count.to_i.to_s}" if count > 0
			sql << ") res" if return_json
      sql*' '
    end
    
    def self.update_sql(where={}, set={}, opts={})
      return "" if where.empty?
      return "" if set.empty?
			
			opts.symbolize!
			
			wrapper_sql(
				:sql => "UPDATE #{table_name} SET #{set.sqlize*','} WHERE #{where.sqlize*' AND '}",
				:return_rows => opts[:return_rows],
				:return_json => opts[:return_json] && Mystic.adapter.name == "postgres"
			)
    end
    
    def self.insert_sql(params={}, opts={})
			return "" if params.empty?
      
			opts.symbolize!

			wrapper_sql(
				:sql => "INSERT INTO #{table_name} (#{params.keys*','}) VALUES (#{params.values.sqlize*','})",
				:return_rows => opts[:return_rows],
				:return_json => opts[:return_json] && Mystic.adapter.name == "postgres"
			)
    end
    
    def self.delete_sql(params={}, opts={})
      return "" if params.empty?
			
			opts.symbolize!

			wrapper_sql(
				:sql => "DELETE FROM #{table_name} WHERE #{params.sqlize*' AND '}",
				:return_rows => opts[:return_rows],
				:return_json => opts[:return_json] && Mystic.adapter.name == "postgres"
			)
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