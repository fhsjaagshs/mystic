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
        }.merge(opts)) unless opts.nil?
      end
      
      def index(*cols)
        opts = cols.delete_at(-1) if cols.last.is_a?(Hash)
        opts ||= {}
        opts[:columns] = cols.concat(opts.delete(:columns) || [])
        self << Index.new({ :tblname => @name }.merge(opts))
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
      raise ArgumentError, "No block provided, blocks are required to create a table." unless block_given?
      table = Mystic::SQL::Table.new(name)
      yield(table)
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
      index = Mystic::SQL::Index.new({
        :name => name,
        :tblname => tblname
      }.merge(opts))
      Mystic.execute(index.to_sql)
    end
    
    def drop_index(*args)
      Mystic.execute(Mystic.adapter.drop_index_sql(*args))
    end
    
    def rename_column(table, oldname, newname)
      Mystic.execute("ALTER TABLE #{table.to_s} RENAME COLUMN #{oldname.to_s} TO #{newname.to_s}")
    end
    
    def rename_table(oldname, newname)
      Mystic.execute("ALTER TABLE #{oldname.to_s} RENAME TO #{newname.to_s}")
    end
    
    def drop_columns(table_name, *col_names)
      Mystic.execute("ALTER TABLE #{table_name.to_s} DROP COLUMN #{col_names*","}") unless col_names.empty?
    end
    
    def add_column(table_name, col_name, kind, opts={})
      col = Mystic::SQL::Column.new({
          :name => col_name,
          :kind => kind
        }.merge(opts))
      Mystic.execute("ALTER TABLE #{table_name.to_s} ADD COLUMN #{col.to_sql}")
    end
  end
end