#!/usr/bin/env ruby

require "connection_pool"
require "mystic/extensions"

UNIVERSAL_TYPES = {
  :date => "DATE",
  :time => "TIME",
  :timestamp => "TIMESTAMP"
  :bool => "BOOLEAN",
  :text => "TEXT",
  :integer => "INTEGER",
  :varchar => "VARCHAR"
}

MYSTIC_CONSTRAINTS_HASH = {
  :unique => "UNIQUE",
  :null => "NULL",
  :not_null => "NOT NULL",
  :primary_key => "PRIMARY KEY"
}

class Adapter
  def name
    self.class.name.split('::').last.gsub("Adapter","").downcase
  end
  
  def create_pool(&block)
    @pool = ConnectionPool::Wrapper.new(:size => 5, :timeout => 5, &block)
  end
  
  def connect(opts)
    
  end
  
  def exec(sql)
    
  end
  
  def sql_kind(kind)
    UNIVERSAL_TYPES[kind.to_sym]
  end

  #
  # These methods are the same across MySQL and PostgreSQL
  #

  def foreign_key_sql(tbl, column, delete_action, update_action)
    sql = "REFERENCES #{tbl}(#{column})"
    
    if delete_action
      del_sql = delete_action.sqlize
      sql << " ON DELETE " + del_sql
    end
    
    if update_action
      update_sql = update_action.sqlize
      sql << " ON UPDATE " + update_sql
    end
    
    return sql
  end
  
  def column_sql(name, kind, size, constraints)
    sql = "#{name} #{kind}"
    sql << "(#{size})" if size.to_s.length > 0
    sql << " " + constraints.join(" ") if constraints.count == 0
    return sql
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
end