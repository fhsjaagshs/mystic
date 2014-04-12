#!/usr/bin/env ruby

require "mystic"
require "connection_pool"

UNIVERSAL_TYPES = {
  :date => "DATE",
  :time => "TIME",
  :timestamp => "TIMESTAMP",
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
    puts sql
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
    sql << " ON DELETE " + fkey.delete_action.sqlize if fkey.delete_action
    sql << " ON UPDATE " + fkey.update_action.sqlize if fkey.update_action
    sql
  end

  def column_sql(col) 
    sql = []
    sql << col.name.to_s
    sql << sql_kind(col.kind.to_sym)
    sql << "(#{col.size})" if col.size.to_s.length > 0 && col.geospatial? == false
    sql << "#{self.geospatial_sql_type(col)}" if col.geospatial?
    sql << "NOT NULL" if col.constraints[:not_null] == true
    sql << "UNIQUE" if col.constraints[:unique] == true
    sql << "PRIMARY KEY" if col.constraints[:primary_key] == true
    sql << "REFERENCES " + col.constraints[:references] if col.constraints.member?(:references)
    sql.join(" ")
  end
  
  def index_sql(index)
    sql = []
    sql << "CREATE"
    sql << "UNIQUE" if index.unique
    sql << index.name.nil? "INDEX ON" : "INDEX #{index.name} ON"
    sql << index.tblname
    sql << "USING #{index.type}" if index.type
    sql << "(" + index.columns.join(",") + ")" if index.columns.is_a?(Array)  
    sql << "(#{index.columns.map { |h| h[:name].to_s + " " + h[:order].to_s }.join(",")})" if index.columns.is_a?(Hash)
    sql << "WITH (#{index.with.inject([]) { |product, key, value| product << key.to_s+"="+value.to_s }.join(" ")})" if index.with
    sql << "TABLESPACE #{index.tablespace}" if index.tablespace
    sql.join(" ")
  end
  
  def constraint_sql(constraint)
    case constraint
    when CheckConstraint
      return "CONSTRAINT #{constr.name} CHECK(#{constr.conditions})"
    when Constraint
      return constraint.sqlize
    end
  end
end