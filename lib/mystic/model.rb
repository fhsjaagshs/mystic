#!/usr/bin/env ruby

module Mystic
  class Model
    def self.table_name
      to_s.downcase
    end
    
    def self.select_sql(opts={})
      count = opts.delete(:count) || 0
      pairs = opts.sqlize
      
      sql = "SELECT #{table_name}.* FROM #{table_name}"
      sql << " WHERE #{pairs*' AND '}" unless pairs.empty?
      sql << " LIMIT #{count.to_i.to_s}" if count > 0
      sql
    end
    
    def self.function_sql(funcname, *params)
      "SELECT " + funcname.to_s + "(" + params.map{ |param| "'" + param.to_s.sanitize + "'" }*',' + ");"
    end
    
    def self.update_sql(where={}, set={})
      where_pairs = where.sqlize
      set_pairs = set.sqlize
      "UPDATE " + table_name + " SET " + set_pairs*',' + " WHERE " + where_pairs*' AND ' unless where_pairs.empty? && set_pairs.empty?
    end
    
    def self.insert_sql(opts={})
      "INSERT INTO " + table_name + "(" + opts.keys*',' + ") VALUES (" + opts.values.map { |value| "'" + value.to_s.sanitize + "'" }*',' + ")" unless opts.empty?
    end
    
    def self.delete_sql(opts={})
      "DELETE FROM " + table_name + " WHERE " + opts.sqlize*' AND ' unless where.empty?
    end
  end
end