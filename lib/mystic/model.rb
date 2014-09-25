#!/usr/bin/env ruby

# opts:
# :return - `:json`, `:rows`, `:nothing` defaults to :rows

module Mystic
  module Model
    def self.included base
      base.extend ClassMethods
    end
    
    module ClassMethods
      def table_name
        to_s.split("::").last.downcase.to_sym
      end
		
  		def visible_cols
  			["*"]
  		end
      
      def col_str
        visible_cols.map { |c| c.to_s == "*" ? "*" : c.to_s.dblquote }*','
      end

  		def decorate sql, opts={}
        raise ArgumentError, "No SQL to decorate." if sql.nil? || sql.empty?

  			op = sql.split(/\s+/,2).first.upcase
        retrn = opts[:return] || opts["return"] || :rows
        singular = (opts[:singular] || opts["singular"] || false) == true
        singular = true if op == "INSERT"

  			sql << " RETURNING #{colstr}" if retrn != :nothing && op != "SELECT"
        
        return sql unless retrn == :json
        
  			s = []
				s << "WITH res AS (#{sql}) SELECT"
				s << "array_to_json(array_agg(res))" unless singular
				s << "row_to_json(res)" if singular
				s << "AS #{Mystic::JSON_COL.dblquote}"
				s << "FROM res"
        s << "LIMIT 1" if singular
  			s*' '
  		end

      def function_sql returns_rows, funcname, *params
  			"SELECT #{returns_rows ? "* FROM" : ""} #{funcname}(#{params.sqlize*','})"
      end
    
      def select_sql params={}, opts={}
        count = opts[:count] || opts["count"] || 0
        count = 1 if (opts[:singlular] || opts["singular"]) == true
  			where = params.sqlize

  			sql = []
  			sql << "SELECT #{col_str} FROM #{table_name}"
  			sql << "WHERE #{where*' AND '}" unless where.empty?
  			sql << "LIMIT #{count.to_i}" if count > 0
			
        decorate sql*' ', opts
      end
    
      def update_sql where={}, set={}, opts={}
        return "" if where.empty?
        return "" if set.empty?
        decorate "UPDATE #{table_name.dblquote} SET #{set.sqlize*','} WHERE #{where.sqlize*' AND '}", opts
      end
    
      def insert_sql params={}, opts={}
  			return "" if params.empty?
        decorate "INSERT INTO #{table_name.dblquote} (#{params.keys*','}) VALUES (#{params.values.sqlize*','})", opts
      end
    
      def delete_sql params={}, opts={}
        return "" if params.empty?
        decorate "DELETE FROM #{table_name.dblquote} WHERE #{params.sqlize*' AND '}", opts
      end
    
      def select params={}, opts={}
        Mystic.execute select_sql(params, opts)
      end
    
      def fetch params={}, opts={}
        res = select params, opts.merge({:singular => true})
        res.is_a? String ? res : (res.first rescue res)
      end
    
      def create params={}, opts={}
        res = Mystic.execute insert_sql(params, opts)
        res.is_a? String ? res : (res.first rescue res)
      end
    
      def update where={}, set={}, opts={}
        res = Mystic.execute update_sql(where, set, opts)
        opts[:singular] ? (res.first rescue res) : res
      end
    
      def delete params={}, opts={}
  			res = Mystic.execute delete_sql(params, opts)
        opts[:singular] ? (res.first rescue res) : res
      end
		
  		def exec_func funcname, *params
  			Mystic.execute function_sql(false, funcname, *params)
  		end
		
  		def exec_func_rows funcname, *params
  			Mystic.execute function_sql(true, funcname, *params)
  		end
    end
  end
end