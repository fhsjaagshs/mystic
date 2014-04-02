#!/usr/bin/env ruby

require "mystic"

module Mystic
  module SQL
    
    class Index
      
      attr_accessor :name, :tblname, :opts, :type, :unique, :using, :concurrently, :with, :columns
      
      def initialize(name, tblname, opts={})
        @name = name
        @tblname = tblname
        @type = opts[:type] # a string/symbol
        @unique = opts[:unique] # a boolean
        @using = opts[:using] # a symbol/string
        @concurrently = opts[:concurrently] # a boolean
        @with = opts[:with] # a hash (keys => [:fillfactor => 10..100, :fastupdate => true])
        @columns = []
      end
      
      # can accept shit other than columns like
      # box(location,location)
      def <<(col)
        @columns << col
      end
      
      def to_sql
        Mystic.adapter.index_sql()
      end
    end
    
    class CheckConstraint
      def initialize(conditions_str, name)
        @conditions = conditions_str.to_s
        @name = name
      end
    
      def to_sql
        Mystic.adapter.constraint_sql(@name, @conditions)
      end
    end
    
    class Constraint
      def initialize(constr)
        @constr = constr
      end
      
      def to_sql
        @constr.sqlize
      end
    end

    class ForeignKey
      def initialize(tbl, column, opts={})
        @tbl = tbl
        @column = column
        @delete = opts[:delete]
        @update = opts[:update]
      end
      
      def to_sql
        Mystic.adapter.foreign_key_sql(@tbl, @column, @delete, @update)
      end
    end
  
    class Column
      def initialize(opts={})
        @name = opts[:name].to_s
        @kind = opts[:kind].to_sym
        @size = opts[:size].to_s
        @constraints = []
      end
    
      def <<(obj)
        case obj
        when Constraint, CheckConstraint, ForeignKey
          @constraints << obj
        end
      end
      
      def [](idx)
        @constraints[idx]
      end
      
      def to_sql
        Mystic.adapter.column_sql(@name, @kind, @size, @constraints.map { |constr| constr.to_sql })
      end
    end
  
    class Table
      def initialize(name)
        @name = name.to_s
        raise ArgumentError, "Argument 'name' is invalid." if @name.length == 0
        @columns = []
      end
    
      def <<(column)
        raise ArgumentError, "Argument is not a Column or a Constraint" if [Mystic::SQL::Constraint, Mystic::SQL::Column].include?(column.class)
        @columns << column
      end
    
      def to_sql
        cols_sql = @columns.inject do |col_string, column|
          col_string << "," + column.to_sql
        end
        "CREATE TABLE #{@name} (#{cols_sql})"
      end
    end
  end
end