#!/usr/bin/env ruby

require "connection_pool"

UNIVERSAL_TYPES = {
  :date => "DATE",
  :time => "TIME",
  :timestamp => "TIMESTAMP"
  :bool => "BOOLEAN",
  :text => "TEXT",
  :integer => "INTEGER",
  :varchar => "VARCHAR"
}

MYSTIC_CONSTRAINTS_HASH = {
  :unique => "UNIQUE",
  :null => "NULL",
  :not_null => "NOT NULL",
  :primary_key => "PRIMARY KEY"
}

class Adapter
  def name
    self.class.name.split('::').last.gsub("Adapter","").downcase
  end
  
  def create_pool(&block)
    @pool = ConnectionPool::Wrapper.new(:size => 5, :timeout => 5, &block)
  end
  
  def connect(opts)
    
  end
  
  def exec(sql)
    
  end
  
  def sql_kind(kind)
    UNIVERSAL_TYPES[kind.to_sym]
  end

  #
  # These methods are the same across MySQL and PostgreSQL
  #

  def foreign_key_sql(tbl, column, delete_action, update_action)
    sql = "REFERENCES #{tbl}(#{column})"
    
    if delete_action
      del_sql = delete_action.to_s.capitalize.split("_").join(" ")
      sql << " ON DELETE " + del_sql
    end
    
    if update_action
      update_sql = update_action.to_s.capitalize.split("_").join(" ")
      sql << " ON UPDATE " + update_sql
    end
    
    return sql
  end
  
  def column_sql(name, kind, size, constraints)
    sql = "#{name} #{kind}"
    sql << "(#{size})" if size.to_s.length > 0
    sql << " " + constraints.join(" ") if constraints.count == 0
    return sql
  end
end