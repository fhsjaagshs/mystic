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
    
    def index(idxname, name, opts={})
      @indeces = { :idxname => idxname, :colname => name, :opts => opts }
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
        index_strings << Mystic.adapter.index_sql(index[:idxname], @name, index[:colname], index[:opts])
      end
      
      @constraints.each do |constraint|
        column_strings << "<CONSTRAINT_HERE>"
      end
      
      "CREATE TABLE #{name} (#{column_strings.join(",")});#{index_strings.join(";")}"
    end
    
  end
    
    
=begin

change_table(name, options): Allows to make column alterations to the table called name. It makes the table object available to a block that can then add/remove columns, indexes or foreign keys to it.

rename_table(old_name, new_name): Renames the table called old_name to new_name.

add_column(table_name, column_name, type, options): Adds a new column to the table called table_name named column_name specified to be one of the following types: :string, :text, :integer, :float, :decimal, :datetime, :timestamp, :time, :date, :binary, :boolean. A default value can be specified by passing an options hash like { default: 11 }. Other options include :limit and :null (e.g. { limit: 50, null: false }) – see ActiveRecord::ConnectionAdapters::TableDefinition#column for details.

rename_column(table_name, column_name, new_column_name): Renames a column but keeps the type and content.

change_column(table_name, column_name, type, options): Changes the column to a different type using the same parameters as add_column.

remove_column(table_name, column_name, type, options): Removes the column named column_name from the table called table_name.

add_index(table_name, column_names, options): Adds a new index with the name of the column. Other options include :name, :unique (e.g. { name: 'users_name_index', unique: true }) and :order (e.g. { order: { name: :desc } }).

remove_index(table_name, column: column_name): Removes the index specified by column_name.

remove_index(table_name, name: index_name): Removes the index specified by index_name.

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
    
    def add_index(table_name, )
    
  end
end