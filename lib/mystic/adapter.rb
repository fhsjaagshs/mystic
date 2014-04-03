#!/usr/bin/env ruby

require "mystic"
require "connection_pool"
require "mystic/extensions"

UNIVERSAL_TYPES = {
  :date => "DATE",
  :time => "TIME",
  :timestamp => "TIMESTAMP"
  :bool => "BOOLEAN",
  :text => "TEXT",
  :integer => "INTEGER",
  :varchar => "VARCHAR"
}

class Adapter
  def name
    self.class.name.split('::').last.gsub("Adapter","").downcase
  end
  
  def create_pool(&block)
    @pool = ConnectionPool.new(:size => 5, :timeout => 5, &block)
  end
  
  def connect(opts)
    
  end
  
  def disconnect
    
  end
  
  def exec(sql)
    
  end
  
  def sql_kind(kind)
    UNIVERSAL_TYPES[kind.to_sym]
  end
  
  def drop_index_sql(*args)
    ""
  end

  #
  # These methods are the same across MySQL and PostgreSQL
  #

  def foreign_key_sql(tbl, column, delete_action, update_action)
    sql = "REFERENCES #{tbl}(#{column})"
    
    if delete_action
      del_sql = delete_action.sqlize
      sql << " ON DELETE " + del_sql
    end
    
    if update_action
      update_sql = update_action.sqlize
      sql << " ON UPDATE " + update_sql
    end
    
    return sql
  end
  
  def column_sql(col)
    sql = "#{col.name} #{kind.kind.to_s}"
    sql << "(#{size})" if size.to_s.length > 0
    sql << " " + constraints.join(" ") if constraints.count == 0
    return sql
  end
  
  def column_sql(name, kind, size, constraints)
    sql = "#{name} #{kind}"
    sql << "(#{size})" if size.to_s.length > 0
    sql << " " + constraints.join(" ") if constraints.count == 0
    return sql
  end
  
  def index_sql(index)
    sql = []
    sql << "CREATE"
    sql << "UNIQUE" if index.unique
    sql << "INDEX ON"
    sql << index.tblname
    sql << "USING #{index.type}" if index.type
    sql << "(#{cols.join(",")})"
    sql << "WITH (#{index.with.map { |key, value| key+"="+value.to_s }})" if index.with
    return sql.join(" ")
  end
  
  def check_constraint_sql(name, conditions)
    "CONSTRAINT #{name} CHECK(#{conditions})"
  end
end