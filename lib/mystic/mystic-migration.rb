#!/usr/bin/env ruby

require "mystic"

module Mystic
  module SQL
    class Table
      def column(col_name, kind, opts={})
        self << Column.new({
          :name => col_name,
          :kind => kind.to_sym
        }.merge(opts))
      end
      
      def varchar(name, opts={})
        raise ArgumentError, "VARCHARs require a size." if opts[:size].nil?
        column(name, :varchar, opts)
      end
      
      def char(name, opts={})
        raise ArgumentError, "CHARs require a size." if opts[:size].nil?
        column(name, :char, opts)
      end

      def geometry(col_name, kind, srid, opts={})
        self << SpatialColumn.new({
          :name => col_name,
          :geom_kind => kind,
          :geom_srid => srid
        }.merge(opts))
      end
      
      def index(*columns, opts={})
        opts[:columns] = opts[:columns].merge(columns) if columns
        self << Index.new({
          :tblname => @name
        }.merge(opts))
      end
      
      def method_missing(meth, *args, &block)
        column(args[0], meth.to_s, args[1])
      end  
    end
  end
  
  class Migration
    def execute(sql)
      Mystic.execute(sql)
    end
    
    def create_table(name)
      table = Mystic::SQL::Table.new(name)
      yield(table) if block_given?
      Mystic.execute(table.to_sql)
    end
    
    def drop_table(name)
      Mystic.execute("DROP TABLE #{name}")
    end
    
    def create_view(name, sql)
      Mystic.execute("CREATE VIEW #{name} AS #{sql}")
    end
    
    def drop_view(name)
      Mystic.execute("DROP VIEW #{name}")
    end
    
    def add_index(tblname, name, opts={})
      raise ArgumentError, "opts parameter must be a hash." if opts.is_a?(Hash) == false
      hash = {
        :name => name,
        :tblname => tblname
      }.merge(opts)
      index = Mystic::SQL::Index.new(hash)
      Mystic.execute(index.to_sql)
    end
    
    def drop_index(*args)
      Mystic.execute(Mystic.adapter.drop_index_sql(*args))
    end
    
    def rename_column(table, oldname, newname)
      Mystic.execute("ALTER TABLE #{table} RENAME COLUMN #{oldname} TO #{newname}")
    end
    
    def rename_table(oldname, newname)
      Mystic.execute("ALTER TABLE #{oldname} RENAME TO #{newname}")
    end
    
    def drop_columns(table_name, *col_names)
      Mystic.execute("ALTER TABLE #{table_name} DROP COLUMN #{col_names.join(",")}") if col_names.count > 0
    end
    
    def add_column(table_name, col_name, kind, opts={})
      col = Mystic::SQL::Column.new({
          :name => name,
          :kind => kind
        }.merge(opts))
      Mystic.execute("ALTER TABLE #{table_name} ADD COLUMN #{col.to_sql}")
    end
  end
end