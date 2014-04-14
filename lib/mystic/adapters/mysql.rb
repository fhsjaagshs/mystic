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
    @pool.shutdown do |instance|
      instance.close
    end
  end
  
  def parse_response(res)
   # row_names = res.fields
    #ret = []
    #res.each_row { |row_array| ret << row_array.merge_keys[row_names] }
    #ret
  end
  
  def exec(sql)
    super
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
    res ||= kind.sqlize
    res
  end
  
  def drop_index_sql(*args)
    index_name, table_name = *args
    "DROP INDEX #{index_name} ON #{table_name}"
  end
  
  def geospatial_sql_type(col)
    ""
  end
end