#!/usr/bin/env ruby

require "mystic"
require "connection_pool"
require "densify"

class Adapter
	attr_accessor :pool_size, :pool_timeout
	
  def name
    self.class.name.split('::').last.delete("Adapter").downcase
  end
  
  def create_pool(&block)
    @pool = ConnectionPool.new(
      :size => pool_size || 5,
      :timeout => pool_timeout || 5,
      &block
    )
  end
  
  def connect(opts)
    
  end
  
  def disconnect
    
  end
  
  def exec(sql)
    nil if @pool.nil?
    sql = sql.densify
    sql << ";" unless sql[-1] == ";"
  end
  
  def parse_response(res)
    
  end
  
  def sql_kind(kind)
    sql_kind = UNIVERSAL_TYPES[kind.to_sym]
    sql_kind ||= kind.sqlize
    sql_kind
  end
  
  def drop_index_sql(*args)
    ""
  end
  
  def geospatial_sql_type(col)
    ""
  end

  #
  # These methods are the same across MySQL and PostgreSQL
  #

  def foreign_key_sql(fkey)
    sql = "REFERENCES #{fkey.tbl}(#{fkey.column})"
    sql << "ON DELETE " + fkey.delete_action.sqlize if fkey.delete_action
    sql << "ON UPDATE " + fkey.update_action.sqlize if fkey.update_action
    sql*" "
  end

  def column_sql(col) 
    sql = []
    sql << col.name.to_s
    sql << sql_kind(col.kind.to_sym)
    sql << "(" + col.size + ")" if col.size && col.geospatial? == false
    sql << self.geospatial_sql_type(col) if col.geospatial?
    sql << "NOT NULL" if col.constraints[:not_null]
    sql << "UNIQUE" if col.constraints[:unique]
    sql << "PRIMARY KEY" if col.constraints[:primary_key]
    sql << "REFERENCES " + col.constraints[:references] if col.constraints.member?(:references)
		sql << "DEFAULT " + col.constraints[:default] if col.constraints.member?(:default)
    sql*" "
  end
  
  def index_sql(index)
    sql = []
    sql << "CREATE"
    sql << "UNIQUE" if index.unique
    sql << "INDEX"
    sql << index.name unless index.name.nil?
    sql << "ON"
    sql << index.tblname
    sql << "USING #{index.type}" if index.type
    sql << "(#{index.columns.map { |h| h[:name].to_s + " " + h[:order].to_s } * ","})" if index.columns.is_a?(Hash)
    sql << "WITH (#{index.with.sql_stringify("=")})" if index.with
    sql << "TABLESPACE #{index.tablespace}" if index.tablespace
    sql*" "
  end
  
  def constraint_sql(constr)
    case constraint
    when CheckConstraint
      "CONSTRAINT #{constr.name} CHECK(#{constr.conditions})"
    when Constraint
      constr.sqlize
    end
  end
end