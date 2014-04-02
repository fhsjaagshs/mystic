#!/usr/bin/env ruby

require "mystic"

CONSTRAINTS_HASH = {
  :unique => "UNIQUE",
  :null => "NULL",
  :not_null => "NOT NULL",
  :primary_key => "PRIMARY KEY"
}

module Mystic
  module SQL
    
    def adapter
      Mystic.adapter
    end
    
    class Index
      def initialize
        
      end
    end
    
    class Constraint
      def initialize(conditions_str, name)
        @conditions = conditions_str.to_s
        @name = name
      end
    
      def to_sql
        Mystic.adapter.constraint_sql(@name, @conditions)
      end
    end

    class ForeignKey
      def initialize
        #
        ## Should this class exist?
        #
      end
    end
  
    class Column
      def initialize(opts={})
        @name = opts[:name].to_s
        @kind = opts[:kind].to_sym
        @size = opts[:size].to_s
        @constraints = []
      end
    
      def <<(constraint)
        @constraints << constraint.to_sql
      end

      def foreign_key(tbl, column, opts={})
        @constraints << Mystic.adapter.foreign_key_sql(tbl,column,opts)
      end
      
      def concat_constraints
        
      end
      
      def to_sql
        Mystic.adapter.column_sql(@name, @kind, @size, )
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