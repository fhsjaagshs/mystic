#!/usr/bin/env ruby

require "mystic"

module Mystic
  module SQL
    class Table
      def varchar(name, opts={})
        raise ArgumentError, "VARCHARs require a size." if opts[:size].nil?
        self << Column.new({
          :name => name,
          :kind => :varchar
        }.merge(opts))
      end
    
      def text(name, opts={})
        self << Column.new({
          :name => name,
          :kind => :text
        }.merge(opts))
      end
    
      def boolean(name, opts={})
        self << Column.new({
          :name => name,
          :kind => :bool
        }.merge(opts))
      end
    
      def integer(name, opts={})
        self << Column.new({
          :name => name,
          :kind => :integer
        }.merge(opts))
      end
      
      def float(name, opts={})
        self << Column.new({
          :name => name,
          :kind => :float
        }.merge(opts))
      end
      
      def column(name, kind, opts={})
        self << Column.new({
          :name => name,
          :kind => kind.to_sym
        }.merge(opts))
      end
      
      def geometry(name, kind, srid, opts={})
        self << SpatialColumn.new({
          :name => name,
          :geom_kind => kind,
          :geom_srid => srid
        }.merge(opts))
      end
      
      def index(name, tblname, opts={})
        self << Index.new({
          :name => name,
          :tblname => tblname
        }.merge(opts))
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
    
    def add_index(name, tblname, opts={})
      index = Mystic::SQL::Index.new({
        :name => name,
        :tblname => tblname
      }.merge(opts))
      Mystic.execute(index.to_sql)
    end
    
    def drop_index(*args)
      Mystic.execute(Mystic.drop_index_sql(*args))
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