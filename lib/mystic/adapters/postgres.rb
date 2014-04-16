#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "pg"

# http://en.wikibooks.org/wiki/Converting_MySQL_to_PostgreSQL#Data_Types
POSTGRES_TYPES = {
  :float => "REAL",
  :double => "DOUBLE PRECISION",
  
  :serial => "SERIAL",
  :json => "JSON",
  :xml => "XML",
  :uuid => "UUID"
}

class PostgresAdapter < Adapter
  def connect(opts)
    create_pool do
      PG.connect(opts)
    end
  end
  
  def disconnect
    @pool.shutdown do |instance|
      instance.close
    end
  end
  
  def parse_response(res)
    row_names = res.fields
    ret = []
    res.each_row { |row_array| ret << row_array.merge_keys(row_names) }
    ret
  end
  
  def exec(sql)
    super
    res = nil
    @pool.with do |instance|
      res = instance.exec(sql)
    end
    
    return parse_response(res)
  end
  
  def sanitize(string)
    res = nil
    @pool.with do |instance|
      res = instance.escape_string(string)
    end
    return res
  end

  def sql_kind(kind)
    res = super(kind)
    res ||= POSTGRES_TYPES[kind.to_sym]
    res ||= kind.sqlize
    res
  end
  
  def drop_index_sql(*args)
    "DROP INDEX #{args.first}"
  end
end