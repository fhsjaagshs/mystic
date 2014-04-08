#!/usr/bin/env ruby

require "mystic"

module Mystic
  module SQL
    class Table
      def varchar(name, size, *constraints)
        self << Column.new(
          :name => name,
          :kind => :varchar,
          :size => size,
          :constraints => constraints
        )
      end
    
      def text(name, *constraints)
        self << Column.new(
          :name => name,
          :kind => :text,
          :constraints => constraints
        )
      end
    
      def boolean(name, opts={})
        self << Column.new(
          :name => name,
          :kind => :boolean,
          :constraints => opts[:constraints]
        )
      end
    
      def integer(name, opts={})
        self << Column.new(
          :name => name,
          :kind => :integer,
          :constraints => opts[:constraints]
        )
      end
      
      def float(name, opts={})
        self << Column.new(
          :name => name,
          :kind => :float,
          :constraints => opts[:constraints]
        )
      end
    
      def index(idxname, cols=[], opts={})
        @indeces << { :idxname => idxname, :cols => cols, :opts => opts }
      end
    end
  end
end

module Mystic
  class Migration
    
    def exec(sql)
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
    
    def add_index(table_name, index_name, cols=[], opts={})
      sql = Mystic.adapter.index_sql(table_name, index_name, cols, opts)
      Mystic.execute(sql)
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
    
    def drop_column(table_name, column_name)
      drop_columns(table_name, [column_name])
    end
    
    def drop_columns(table_name, col_names=[])
      if col_names.count > 0
        Mystic.execute("ALTER TABLE #{table_name} DROP COLUMN #{col_names.join(",")}")
      end
    end
    
    def add_column(table_name, col_name, type, opts={})
      column_sql = Mystic.adapter.column_sql(type.to_sym, column_name, opts)
      Mystic.execute("ALTER TABLE #{table_name} ADD COLUMN #{column_sql}")
    end
  end
end