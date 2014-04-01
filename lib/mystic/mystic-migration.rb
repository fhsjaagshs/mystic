#!/usr/bin/env ruby

module Mystic
  class Table
    def initialize(name)
      @name = name
      @columns = [] # contains column names
      @constraints = [] # contains constraints
      @indeces = []
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
      column(:integer, name, opts)
    end
    
    def index(idxname, cols=[], opts={})
      @indeces << { :idxname => idxname, :cols => cols, :opts => opts }
    end
    
    def constraint(constraint_sql)
      @constraints << constraint_sql
    end
    
    def check(criteria)
      @constraints << "CHECK (#{criteria})"
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
      
      column_strings.push *@constraints
      
      column_strings.compact!
      index_strings.compact!
      
      sql = "CREATE TABLE #{@name} (#{column_strings.join(",")})"
      sql << ";#{index_strings.join(";")}" if index_strings.count > 0
      sql
    end
  end

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
    
    def add_column(table_name, col_name, type, opts={})
      column_sql = Mystic.adapter.column_sql(type.to_sym, column_name, opts)
      Mystic.execute("ALTER TABLE #{table_name} ADD COLUMN #{column_sql}")
    end
  end
end