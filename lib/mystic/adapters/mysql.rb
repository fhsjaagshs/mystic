#!/usr/bin/env ruby

require "mystic/adapter"
require "mysql2"

POSTGRES_TYPES = {
  :float => "REAL",
  :double => "DOUBLE PRECISION",
  
  :serial => "SERIAL",
  :json => "JSON",
  :xml => "XML",
  :uuid => "UUID"
}

class MysqlAdapter < Adapter
  def connect(opts)
    create_pool do
      Mysql2::Client.new(opts)
    end
  end
  
  def disconnect
    @pool.with do |instance|
      instance.close
    end
  end
  
  def exec(sql)
    return nil if @pool.nil?
    puts sql
    res = nil
    @pool.with do |instance|
      res = instance.query(sql)
    end
    return res
  end
  
  def sanitize(string)
    res = nil
    @pool.with do |instance|
      res = instance.escape(string)
    end
    return res
  end
  
  def sql_kind(kind)
    res = super(kind)
    res ||= MYSQL_TYPES[kind.to_sym]
    res
  end
  
  def constraint_sql(name, conditions)
    "CONSTRAINT #{name} CHECK(#{conditions})"
  end
  
  def drop_index_sql(*args)
    index_name, table_name = *args
    "DROP INDEX #{index_name} ON #{table_name}"
  end
end