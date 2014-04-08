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
        case col
        when Column
          @columns << col.name.to_s;
        when String
          @columns << col;
        else
          raise ArgumentError, "Column must be a String or a Mystic::SQL::Column"
        end
      end

      def to_sql
        Mystic.adapter.index_sql(self)
      end
      
      alias_method :to_s, :to_sql
      alias_method :push, :<<
    end
    
    class Constraint
      attr_accessor :constr
      def initialize(constr)
        @constr = constr
      end
      
      def to_sql
        Mystic.adapter.constraint_sql(self)
      end
      
      alias_method :to_s, :to_sql
    end
    
    class CheckConstraint < Constraint
      attr_accessor :conditions, :name
      def initialize(conditions_str, name)
        @conditions = conditions_str.to_s
        @name = name
      end
    end

    class ForeignKey
      attr_accessor :tbl, :column, :delete, :update
      
      def initialize(tbl, column, opts={})
        @tbl = tbl
        @column = column
        @delete = opts[:delete]
        @update = opts[:update]
      end
      
      def to_sql
        Mystic.adapter.foreign_key_sql(self)
      end
      
      alias_method :to_s, :to_sql
    end
  
    class Column
      attr_accessor :name, :kind, :size, :constraints
      
      def initialize(opts={})
        @name = opts[:name].to_s
        @kind = opts[:kind].to_sym
        @size = opts[:size].to_s
        @constraints = opts[:constraints] || []
        puts opts
      end
      
      def geospatial?
        false
      end
    
      def <<(obj)
        case obj
        when Constraint, CheckConstraint, ForeignKey
          @constraints << obj
        else
          raise ArgumentException, "Argument must be a Mystic::SQL::Constraint or subclass of said class."
        end
      end
      
      def [](idx)
        @constraints[idx]
      end
      
      def to_sql
        Mystic.adapter.column_sql(self)
      end
      
      alias_method :to_s, :to_sql
      alias_method :push, :<<
    end
  
    class SpatialColumn < Column
      attr_accessor :geom_kind, :geom_srid
      
      def initialize(opts={})
        super
        @geom_kind = opts[:geom_kind]
        @srid = opts[:geom_srid]
      end
      
      def geospatial?
        true
      end
      
      alias_method :to_s, :to_sql
    end
  
    class Table
      attr_accessor :name, :columns, :indeces
      
      def initialize(name)
        @name = name.to_s
        raise ArgumentError, "Argument 'name' is invalid." if @name.length == 0
        @columns = []
        @indeces = []
      end
    
      def <<(obj)
        case obj
        when Column, Constraint
          @columns << obj;
        when Index
          @indeces << obj;
        else
          raise ArgumentError, "Argument is not a Mystic::SQL::Column, Mystic::SQL::Constraint, or Mystic::SQL::Index."
        end
      end
      
      def [](idx)
        @columns[idx]
      end
    
      def to_sql
        raise ArgumentError, "Table cannot have zero columns." if @columns.count == 0
        cols_sql = @columns.map { |col| col.to_sql }.join(",")
        sql = "CREATE TABLE #{@name} (#{cols_sql});"
        sql << @indeces.map { |index| index.to_sql }.join(";") if @indeces.count > 0
        sql
      end
      
      alias_method :to_s, :to_sql
      alias_method :push, :<<
    end
  end
end