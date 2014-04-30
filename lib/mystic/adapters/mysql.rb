#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "mysql2"

MYSQL_TYPES = {
  :float => "FLOAT",
  :double => "DOUBLE"
}

class MysqlAdapter < Adapter
  def connect(opts)
    create_pool do
      Mysql2::Client.new(opts)
    end
  end
  
  def disconnect
    @pool.shutdown(&:close)
  end
  
  def parse_response(res)
    res.to_a
  end
  
  def exec(sql)
    super
    res = nil
    @pool.with { |inst| res = inst.query(sql) }
    parse_response(res)
  end
  
  def sanitize(string)
    res = nil
    @pool.with { |inst| res = inst.escape(string) }
    res
  end
  
  def sql_kind(kind)
    res = super(kind)
    res ||= MYSQL_TYPES[kind.to_sym]
    res ||= kind.sqlize
    res
  end
  
  def drop_index_sql(*args)
    index_name, table_name = *(args[0..1])
    "DROP INDEX #{index_name} ON #{table_name}"
  end
  
  def geospatial_sql_type(col)
    ""
  end
end