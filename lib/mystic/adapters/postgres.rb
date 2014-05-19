#!/usr/bin/env ruby

require "mystic"
require "mystic/adapter"
require "pg"

class PostgresAdapter < Adapter
  def connect(opts)
    create_pool do
      PG.connect(opts)
    end
  end
  
  def disconnect
    @pool.shutdown { |inst| inst.close }
  end
  
  def parse_response(res)
    ret = []
    res.each_row { |row_array| ret << row_array.merge_keys(res.fields) }
    ret
  end
  
  def exec(sql)
    super
    res = nil
    @pool.with { |inst| res = inst.exec(sql) }
    parse_response(res)
  end
  
  def sanitize(string)
    res = nil
    @pool.with { |inst| res = inst.escape_string(string) }
    res
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