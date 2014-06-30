#!/usr/bin/env ruby

module Mystic
  class Model
    def self.table_name
      to_s.downcase
    end
		
		def self.visible_cols
			["*"]
		end
		
		def self.wrapper_sql(opts={})
			sym_opts = opts.symbolize

			sql = sym_opts[:sql] || "SELECT 1"
			return_rows = sym_opts[:return_rows] || false
			return_json = sym_opts[:return_json] || false
			return_rows = true if return_json
			
			op = sql.split(/\s+/,2).first
			
			sql << " RETURNING #{visible_cols*','}" if return_rows && op != "SELECT"
			
			s = []
			
			if return_json
				s << "WITH res AS (#{sql}) SELECT"
				s << "row_to_json(res)" if op == "INSERT"
				s << "array_to_json(array_agg(res))" unless op == "INSERT"
				s << "AS #{Mystic::JSON_COL}"
				s << "FROM res"
			else
				s << sql
			end
			
			s*' '
		end

    def self.function_sql(retuns_rows, funcname, *params)
			"SELECT #{returns_rows ? "* FROM" : ""} #{funcname} (#{fnc_parameterize(params)*','})"
    end
    
    def self.select_sql(params={}, opts={})
			sym_opts = opts.symbolize
      count = sym_opts[:count] || 0
			
			sql = "SELECT #{visible_cols*','} FROM #{table_name} WHERE #{params.sqlize*' AND '}"
			sql << " LIMIT #{count.to_i}" if count > 0
			
			wrapper_sql(
				:sql => sql,
				:return_rows => true,
				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?
			)
    end
    
    def self.update_sql(where={}, set={}, opts={})
      return "" if where.empty?
      return "" if set.empty?
			
			sym_opts = opts.symbolize
			
			wrapper_sql(
				:sql => "UPDATE #{table_name} SET #{set.sqlize*','} WHERE #{where.sqlize*' AND '}",
				:return_rows => sym_opts[:return_rows],
				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?
			)
    end
    
    def self.insert_sql(params={}, opts={})
			return "" if params.empty?
      
			sym_opts = opts.symbolize
			
			wrapper_sql(
				:sql => "INSERT INTO #{table_name} (#{params.keys*','}) VALUES (#{params.values.sqlize*','})",
				:return_rows => sym_opts[:return_rows],
				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?
			)
    end
    
    def self.delete_sql(params={}, opts={})
      return "" if params.empty?
			
			sym_opts = opts.symbolize

			wrapper_sql(
				:sql => "DELETE FROM #{table_name} WHERE #{params.sqlize*' AND '}",
				:return_rows => sym_opts[:return_rows],
				:return_json => sym_opts[:return_json] && Mystic.adapter.json_supported?
			)
    end
    
    def self.select(params={}, opts={})
      Mystic.execute select_sql(params, opts)
    end
    
    def self.fetch(params={}, opts={})
      res = select(params,opts.merge({:count => 1}))
			return res if res.is_a?(String)
			res.first
    end
    
    def self.create(params={}, opts={})
      res = Mystic.execute insert_sql(params, opts)
			return res.first if res.is_a?(Array)
			res
    end
    
    def self.update(where={}, set={}, opts={})
      Mystic.execute update_sql(where, set, opts.merge({ :return_rows => true }))
    end
    
    def self.delete(params={}, opts={})
			Mystic.execute delete_sql(params, opts)
    end
		
		def self.exec_func(funcname, *params)
			Mystic.execute function_sql(false, funcname, *params)
		end
		
		def self.exec_func_rows(funcname, *params)
			Mystic.execute function_sql(true, funcname, *params)
		end
    
    private
    
    def self.fnc_parameterize(params)
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