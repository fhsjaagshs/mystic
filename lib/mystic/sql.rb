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
        @columns << col.name; return if col.is_a?(Column)
        @columns << coll; return if col.is_a?(String)
        raise ArgumentError, "Column must be a String or a Mystic::SQL::Column" if col.is_a
      end

      def to_sql
        Mystic.adapter.index_sql(self)
      end
      
      alias_method :to_s, :to_sql
      alias_method :push, :<<
    end
    
    class CheckConstraint
      attr_accessor :conditions, :name
      def initialize(conditions_str, name)
        @conditions = conditions_str.to_s
        @name = name
      end
    
      def to_sql
        Mystic.adapter.constraint_sql(self)
      end
      
      alias_method :to_s, :to_sql
    end
    
    class Constraint
      attr_accessor :constr
      def initialize(constr)
        @constr = constr
      end
      
      def to_sql
        @constr.sqlize
      end
      
      alias_method :to_s, :to_sql
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
  
    class Column
      attr_accessor :name, :kind, :size, :constraints
      
      def initialize(opts={})
        @name = opts[:name].to_s
        @kind = opts[:kind].to_sym
        @size = opts[:size].to_s
        @constraints = opts[:constraints]
      end
      
      def geospatial?
        false
      end
    
      def <<(*objects)
        objects.each do |obj|
          case obj
          when Constraint, CheckConstraint, ForeignKey
            @constraints << obj
          end
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
  
    class Table
      attr_accessor :name, :columns, :indeces
      
      def initialize(name)
        @name = name.to_s
        raise ArgumentError, "Argument 'name' is invalid." if @name.length == 0
        @columns = []
        @indeces = []
      end
    
      def <<(obj)
        @columns << obj; return if obj.is_a?(Column) || obj.is_a?(Constraint)
        @indeces << obj; return if obj.is_a?(Index)
        raise ArgumentError, "Argument is not a Mystic::SQL::Column or a Mystic::SQL::Constraint."
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