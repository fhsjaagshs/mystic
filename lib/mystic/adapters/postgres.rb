#!/usr/bin/env ruby

require "mystic/adapter"
require "pg"

=begin
  t.float
  t.decimal
  t.datetime
  t.timestamp
  t.time
  t.date
  t.binary
=end

POSTGRES_INDEX_ORDERS = {
  :"" => "ASC",
  :asc => "ASC",
  :desc => "DESC",
  :nulls_first => "NULLS FIRST",
  :nulls_last => "NULLS LAST"
}

POSTGRES_INDEX_TYPES = {
  :"" => "btree",
  :btree => "btree",
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
  
  :varchar => 255
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
    
    return [] if opts.length == 0
    
    opt_strings = []
    
    opts.each do |key, value|
      case key
      when :not_null
        opt_strings << "NOT NULL" if value == true
      when :unique
        opt_strings << "UNIQUE" if value == true
      when :primary_key
        opt_strings << "PRIMARY KEY" if value == true
      when :autoincrement
        opt_strings << "AUTOINCREMENT" if value == true
      end
    end
    
    return opt_strings
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
  
  def column_sql(type,name,opts)
    return nil if type.nil?
    return nil if name.nil?
    
    size = opts[:size] ? opts.delete(:size) : max_length_for(type.to_sym)
    column_string = "#{name.to_s} #{type.to_s}"
    
    if name() == "postgis" && 
      column_string << "(#{opts[:geom_kind].to_s.downcase.capitalize},#{opts[:geom_srid].to_i.to_s})" if size != nil
    else
      column_string << "(#{size.to_s})" if size != nil
    end

    opt_strings = sqlize_opts(opts)
    
    column_string << " " + opt_strings.join(" ") if opt_strings.count > 0

    return column_string
  end
  
end