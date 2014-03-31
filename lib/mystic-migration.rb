#!/usr/bin/env ruby

module Mystic
  class Table
    @columns = [] # contains column names
    @constraints = [] # contains constraints
    @indeces = []
    
    def initialize(name)
      @name = name
      super
    end

    def varchar(name, opts={})
      column(:varchar, name, opts)
    end
    
    def text(name, opts={})
      column(:text, name, opts)
    end
    
    def boolean(name, opts={})
      column(:boolean, name, opts)
    end
    
    def integer(name, opts={})
      
    end
    
    def index(idxname, cols=[], opts={})
      @indeces << { :idxname => idxname, :cols => cols, :opts => opts }
    end
    
    def constraint(constraint_sql)
      @constraints << constraint_sql
    end
    
    def check(criteria)
      # implement a check
    end
    
    def column(type, name, opts={})
      @columns << { :type => type, :name => name, :opts => opts }
    end
    
    def to_sql
      column_strings = []
      index_strings = []
      
      @columns.each do |column|
        column_strings << Mystic.adapter.column_sql(column[:type], column[:name], column[:opts])
      end
      
      @indeces.each do |index|
        index_strings << Mystic.adapter.index_sql(@name, index[:idxname], index[:cols], index[:opts])
      end
      
      column_strings += @constraints
      
      "CREATE TABLE #{name} (#{column_strings.join(",")});#{index_strings.join(";")}"
    end
    
  end
    
    
=begin
add_column(table_name, column_name, type, options): Adds a new column to the table called table_name named column_name specified to be one of the following types: :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean. A default value can be specified by passing an options hash like { default: 11 }. Other options include :limit and :null (e.g. { limit: 50, null: false }) – see ActiveRecord::ConnectionAdapters::TableDefinition#column for details.
change_column(table_name, column_name, type, options): Changes the column to a different type using the same parameters as add_column.
=end
    
  class Migration
    def create_table(name)
      table = Mystic::Table.new(name)
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
    
    def drop_index(index_name)
      Mystic.execute("DROP INDEX #{index_name}")
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
    
  end
end