#!/usr/bin/env ruby

# opts:
# :return - `:json`, `:rows`, `:nothing` defaults to :rows

module Mystic
  module Model
    RETURN_TYPES = [:rows, :json, :nothing]
    def self.included base
      base.extend ClassMethods
    end
    
    module ClassMethods
      def table_name; to_s.split("::").last.downcase.to_sym; end
      def visible_cols; []; end
      def col_str; visible_cols.empty? ? "*" : visible_cols.map { |c| c.to_s.dblquote }*','; end

      def decorate sql, opts={}
        raise ArgumentError, "No SQL to decorate." if sql.nil? || sql.empty?
        
        retrn = opts[:return] || opts["return"] || :rows
        singular = (opts[:singular] || opts["singular"] || false) == true
        singular = true if sql[0..5] == "INSERT"
        
        raise ArgumentError, "Return type (:return) must be either #{RETURN_TYPES.map(&:to_s).join(", ")}" unless RETURN_TYPES.include? retrn

        sql << " RETURNING #{colstr}" if retrn != :nothing && sql[0..5] != "SELECT"
        
        case retrn
        when :rows, :nothing then sql
        when :json
          s = ["SELECT"]
          s << singular ? "row_to_json(\"res\")" : "array_to_json(array_agg(\"res\"))"
          s << "AS #{Mystic::Postgres::REPR_COL.dblquote}"
          s << "FROM (#{sql}) \"res\""
          s << "LIMIT 1" if singular
          s*' '
        end
      end
        
      def function_sql returns_rows, funcname, *params
  			"SELECT #{returns_rows ? "* FROM" : ""} #{funcname}(#{params.sqlize*','})"
      end
    
      def select_sql params={}, opts={}
        count = opts[:count] || opts["count"] || 0
        count = 1 if (opts[:singlular] || opts["singular"]) == true
  			where = params.sqlize

  			sql = ["SELECT #{col_str} FROM #{table_name}"]
  			sql << "WHERE #{where*' AND '}" unless where.empty?
  			sql << "LIMIT #{count.to_i}" if count > 0
			
        decorate sql*' ', opts
      end
    
      def update_sql where={}, set={}, opts={}
        raise ArgumentError, "Update queries must set something." if set.empty?
        decorate "UPDATE #{table_name.dblquote} SET #{set.sqlize*','} WHERE #{where.sqlize*' AND '}", opts
      end
    
      def insert_sql entry={}, opts={}
        decorate "INSERT INTO #{table_name.dblquote} (#{entry.keys*','}) VALUES (#{entry.values.sqlize*','})", opts
      end
    
      def delete_sql params={}, opts={}
        decorate "DELETE FROM #{table_name.dblquote} WHERE #{params.sqlize*' AND '}", opts
      end
    
      def select params={}, opts={}
        Mystic.execute select_sql(params, opts)
      end
    
      def fetch params={}, opts={}
        res = select params, opts.merge({:singular => true})
        res.is_a? String ? res : (res.count > 0 ? res.first : {})
      end
    
      def create params={}, opts={}
        res = Mystic.execute insert_sql(params, opts.merge({:singular => true}))
        res.is_a? String ? res : (res.count > 0 ? res.first : {})
      end
    
      def update where={}, set={}, opts={}
        res = Mystic.execute update_sql(where, set, opts)
        opts[:singular] ? (res.count > 0 ? res.first : {}) : res
      end
    
      def delete params={}, opts={}
  			res = Mystic.execute delete_sql(params, opts)
        opts[:singular] ? (res.count > 0 ? res.first : {}) : res
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