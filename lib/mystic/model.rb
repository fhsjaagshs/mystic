#!/usr/bin/env ruby

class Hash
  def sqlize
    self.reject{ |key, value| value.to_s.length == 0 }.inject([]) { |pairs, key, value| pairs << "#{key.to_s.sanitize}='#{value.to_s.sanitize}'"; pairs }
  end
end

module Mystic
  class Model
    def self.table_name
      self.to_s.downcase
    end
    
    def self.select_sql(opts={})
      count = opts.delete(:count) || 0
      pairs = opts.sqlize
      
      sql = "SELECT * FROM #{self.table_name}"
      sql << " WHERE #{pairs.join(" AND ")}" if pairs.count > 0
      sql << " LIMIT #{count.to_i.to_s}" if count > 0
      sql
    end
    
    def self.function_sql(funcname, *params)
      params.map!{ |param| "'" + param.to_s.sanitize + "'" }
      "SELECT " + funcname.to_s "(" + params.join(",") + ");"
    end
    
    def self.update_sql(where={}, set={})
      where_pairs = where.sqlize
      set_pairs = set.sqlize
      return nil if where_pairs.count == 0
      return nil if set_pairs.count == 08
      
      "UPDATE " + self.table_name + " SET " + set_pairs.join(",") + " WHERE " + where_pairs.join(" AND ")
    end
    
    def self.insert_sql(opts={})
      return nil if opts.length == 0
      "INSERT INTO " + self.table_name + "(" + opts.keys.join(",") + ") VALUES (" + opts.values.map { |value| "'" + value.to_s.sanitize + "'" }.join(",") + ")"
    end
    
    def self.delete_sql(opts={})
      where = opts.sqlize
      return nil if where.length == 0
      
      "DELETE FROM " + self.table_name + " WHERE " + where.join(" AND ")
    end
    
  end
end