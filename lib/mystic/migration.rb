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
    def add(obj)
      Mystic.execute(obj.to_sql)
    end
    
    def create_table(name)
      raise ArgumentError, "No block provided, blocks are required to create a table." unless block_given?
      table = Mystic::SQL::Table.new(name)
      yield(table)
      add(table)
    end
    
    def drop_table(name)
      op = Mystic::SQL::Operation.new(
        :kind => :drop_table,
        :table_name => name.to_s
      )
      add(op)
    end
    
    def create_view(name, sql)
      op = Mystic::SQL::Operation.new(
        :kind => :create_view,
        :view_name => name.to_s,
        :view_sql => sql.to_s
      )
      add(op)
    end
    
    def drop_view(name)
      op = Mystic::SQL::Operation.new(
        :kind => :drop_view,
        :view_name => name.to_s
      )
      add(op)
    end
    
    def add_index(tblname, name, opts={})
      index = Mystic::SQL::Index.new({
        :name => name.to_s,
        :tblname => tblname.to_s
      }.merge(opts))
      add(index)
    end
    
    def drop_index(*args)
      op = Mystic::SQL::Operation.new(
        :kind => :drop_index,
        :index_name => args[0].to_s,
        :table_name => args[1].to_s
      )
      add(op)
    end
    
    def rename_column(table, oldname, newname)
      op = Mystic::SQL::Operation.new(
        :kind => :rename_column,
        :table_name => table.to_s,
        :old_col_name => oldname.to_s,
        :new_col_name => newname.to_s
      )
      add(op)
    end
    
    def rename_table(oldname, newname)
      op = Mystic::SQL::Operation.new(
        :kind => :rename_table,
        :old_name => oldname.to_s,
        :new_name => newname.to_s
      )
      add(op)
    end
    
    def drop_columns(table_name, *col_names)
      op = Mystic::SQL::Operation.new(
        :kind => :drop_columns,
        :table_name => table_name.to_s,
        :column_names => col_names.map(&:to_s)
      )
      add(op)
    end
    
    def add_column(table_name, col_name, kind, opts={})
      op = Mystic::SQL::Operation.new(
        :kind => :add_column,
        :table_name => table_name.to_s,
        :column => Mystic::SQL::Column.new({
          :name => col_name,
          :kind => kind
        }.merge(opts))
      )
      add(op)
    end
  end
end