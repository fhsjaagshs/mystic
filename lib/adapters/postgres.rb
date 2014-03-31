#!/usr/bin/env ruby

require "adapter"
require "pg"

=begin
  t.string
  t.text
  t.integer
  t.float
  t.decimal
  t.datetime
  t.timestamp
  t.time
  t.date
  t.binary
  t.boolean
=end

POSTGRES_INDEX_ORDERS = {
  :asc => "ASC", # the default
  :desc => "DESC",
  :nulls_first => "NULLS FIRST",
  :nulls_last => "NULLS LAST"
}

POSTGRES_INDEX_TYPES = {
  :btree => "btree", # the default
  :hash => "hash", 
  :gist => "gist",
  :gin => "gin"
}

POSTGRES_SIZES = {
  # boolean
  :boolean => 1,
  
  # numerical
  :smallint => 2,
  :integer => 4,
  :bigint => 8,
  :decimal => -1,
  :numeric => -1,
  :real => 4,
  :double_precision => 8,
  :smallserial => 2,
  :serial => 4,
  :bigserial => 8,
  
  # geometric/spatial
  # n is the number of points
  :point => 16,
  :line => 32,
  :lseg => 32,
  :box => 32, # 16+16n bytes
  :path => -1, # 16+16n bytes
  :polygon => -1, # 40+16n bytes
  :circle => 24,
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
  
  def exec(sql)
    pool_instance.exec(sql)
  end
  
  def sanitize(string)
    pool_instance.escape_string(string)
  end
  
  def size_hash
    return POSTGRES_SIZES
  end
  
  def idx_types_hash
    return POSTGRES_INDEX_TYPES
  end
  
  def idx_orders_hash
    return POSTGRES_INDEX_ORDERS
  end
  
  def sqlize_opts(opts)
    opt_strings = []
    
    opts.each do |key, value|
      case key
      when :not_null
        opt_strings << "NOT NULL" if value == true
      when :unique
        opt_strings << "UNIQUE" if value == true
      when :primary_key
        opt_strings << "PRIMARY KEY" if value == true
      end
    end
    
    return opt_strings
  end
  
  def index_sql(idx_name, tablename, colname, opts)
    # opts:
    # :type => the index type (:btree, :hash, :gist, or :gin)
    # :order => :asc, :desc, :nulls_first, :nulls_last
    # :fastupdate => true/false
    
    type_sym = opts[:type].to_sym
    order_sym = opts[:order].to_sym
    
    type_str = idx_types_hash[type_sym]
    order_str = idx_orders_hash[order_sym]
    
    "CREATE INDEX #{idx_name} .... "
    
  end
  
  def column_sql(type,name,opts)
    size = opts[:size] ? opts[:size] : max_length_for(type.to_sym)
    column_string = "#{name.to_s} #{type.to_s}(#{size.to_s})"
    
    opt_strings = sqlize_opts(opts)

    return column_string + " " + opt_strings.join(" ")
  end
  
end