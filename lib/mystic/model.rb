#!/usr/bin/env ruby

module Mystic
  module Model
    def self.included base
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end
    
    module ClassMethods
      def table_name
        to_s.downcase
      end
		
  		def visible_cols
  			["*"]
  		end
		
  		def wrapper_sql opts={}
  			sym_opts = opts.symbolize

  			sql = sym_opts[:sql] || "SELECT 1"
  			op = sql.split(/\s+/,2).first.upcase
  			return_rows = sym_opts[:return_rows] || false
  			return_json = sym_opts[:return_json] || false
  			return_rows = true if return_json
  			plural = opts[:plural] && op != "INSERT"
			
  			sql << " RETURNING #{visible_cols*','}" if return_rows && op != "SELECT"
			
  			s = []
			
  			if return_json
  				s << "WITH res AS (#{sql}) SELECT"
  				s << "array_to_json(array_agg(res))" if plural
  				s << "row_to_json(res)" unless plural
  				s << "AS #{Mystic::JSON_COL}"
  				s << "FROM res"
  			else
  				s << sql
  			end
			
  			s*' '
  		end

      def function_sql returns_rows, funcname, *params
  			"SELECT #{returns_rows ? "* FROM" : ""} #{funcname}(#{params.sqlize*','})"
      end
    
      def select_sql params={}, opts={}
  			sym_opts = opts.symbolize
        count = sym_opts[:count] || 0
  			where = params.sqlize

  			sql = []
  			sql << "SELECT #{visible_cols*','} FROM #{table_name}"
  			sql << "WHERE #{where*' AND '}" if where.count > 0
  			sql << "LIMIT #{count.to_i}" if count > 0
			
  			wrapper_sql(
  				:sql => sql.join(' '),
  				:return_rows => true,
  				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?,
  				:plural => count > 1
  			)
      end
    
      def update_sql where={}, set={}, opts={}
        return "" if where.empty?
        return "" if set.empty?
			
  			sym_opts = opts.symbolize
			
  			wrapper_sql(
  				:sql => "UPDATE #{table_name} SET #{set.sqlize*','} WHERE #{where.sqlize*' AND '}",
  				:return_rows => sym_opts[:return_rows],
  				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?
  			)
      end
    
      def insert_sql params={}, opts={}
  			return "" if params.empty?
      
  			sym_opts = opts.symbolize
			
  			wrapper_sql(
  				:sql => "INSERT INTO #{table_name} (#{params.keys*','}) VALUES (#{params.values.sqlize*','})",
  				:return_rows => sym_opts[:return_rows],
  				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?
  			)
      end
    
      def delete_sql params={}, opts={}
        return "" if params.empty?
			
  			sym_opts = opts.symbolize

  			wrapper_sql(
  				:sql => "DELETE FROM #{table_name} WHERE #{params.sqlize*' AND '}",
  				:return_rows => sym_opts[:return_rows],
  				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?
  			)
      end
    
      def select params={}, opts={}
        Mystic.execute select_sql(params, opts)
      end
    
      def fetch params={}, opts={}
        res = select params, opts.merge({:count => 1})
  			return res if res.is_a? String
  			res.first rescue nil
      end
    
      def create params={}, opts={}
        res = Mystic.execute insert_sql(params, opts)
  			return res if res.is_a? String
  			res.first rescue nil
      end
    
      def update where={}, set={}, opts={}
        Mystic.execute update_sql(where, set, opts.merge({ :return_rows => true }))
      end
    
      def delete params={}, opts={}
  			Mystic.execute delete_sql(params, opts)
      end
		
  		def exec_func funcname, *params
  			Mystic.execute function_sql(false, funcname, *params)
  		end
		
  		def exec_func_rows funcname, *params
  			Mystic.execute function_sql(true, funcname, *params)
  		end
    end
    
    module InstanceMethods
      
    end
  end
end