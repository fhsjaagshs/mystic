#!/usr/bin/env ruby

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

POSTGRES_INDEX_ORDERS = {
  :"" => "ASC", # default
  :asc => "ASC",
  :desc => "DESC",
  :nulls_first => "NULLS FIRST",
  :nulls_last => "NULLS LAST"
}

POSTGRES_INDEX_TYPES = {
  :"" => "btree", # default
  :btree => "btree",
  :hash => "hash", 
  :gist => "gist",
  :gin => "gin"
}

module Mystic
  class Table
    def array(name,  opts={})
      column(:array, name, opts)
    end
  end
end

class PostgresAdapter < Adapter
  
  def connect(opts)
    create_pool do
      PG.connect(opts)
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
      res = instance.exec(sql)
    end
    return res
  end
  
  def sanitize(string)
    res = nil
    @pool.with do |instance|
      res = instance.escape_string(string)
    end
    return res
  end
  
  def idx_types_hash
    return POSTGRES_INDEX_TYPES
  end
  
  def idx_orders_hash
    return POSTGRES_INDEX_ORDERS
  end
  
  def index_sql(relation_name, index_name, cols, opts)
    # opts:
    # :type => the index type (:btree, :hash, :gist, or :gin)
    # :order => :asc, :desc, :nulls_first, :nulls_last
    return nil if cols.count == 0
    
    with = opts[:with]
    type = idx_types_hash[opts[:type].to_s.to_sym]
    unique = opts[:unique]

    cols_sql = cols.map do |col_hash|
      col_name = col_hash[:name]
      col_name = col_hash[:expression] if col_name.nil?
      col_order = idx_orders_hash[col_hash[:order].to_s.to_sym]
      "#{name}#{ col_order ? " " + col_order : "" }"
    end
    
    "CREATE#{unique ? " UNIQUE " : " "}INDEX #{idx_name} ON #{tablename} USING #{type} (#{cols_sql.join(",")})#{ with ? " WITH (#{with})" : ""}"
  end
  
  def foreign_key_sql(tbl, column, opts)
    references = "REFERENCES #{foreign_key}"
    
    opts.each do |key, value|
      case key.to_sym
      when :delete
        references << " ON DELETE #{value.to_s.upcase}"
      when :update
        references << " ON UPDATE #{value.to_s.upcase}"
      end
    end
  end
  
  def constraint_sql(name, conditions)
    "CONSTRAINT #{name} CHECK(#{conditions})"
  end
  
  def column_sql(name, kind, size, constraints)
    sql = "#{@name} #{@kind}"
    sql << "(#{@size})" if size
    sql << " " + "constraints"
    return sql
  end
end