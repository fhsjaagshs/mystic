#!/usr/bin/env ruby

require "mystic"

module Mystic
  module SQL
    class Index
      attr_accessor :name, :tblname, :opts, :type, :unique, :using, :concurrently, :with, :columns, :tablespace
      
      def initialize(opts={})
        @name = opts[:name]
        @tblname = opts[:tblname]
        @type = opts[:type] || :btree # a string/symbol
        @unique = opts[:unique] # a boolean
        @concurrently = opts[:concurrently] # a boolean
        @with = opts[:with] # a hash (keys => { :fillfactor => 10..100, :fastupdate => true })
        @tablespace = opts[:tablespace]
        @columns = opts[:columns] || []
      end
      
      # can accept shit other than columns like
      # box(location,location)
      def <<(col)
        case col
        when Column
          @columns << { :name => col.name.to_s }
        when String
          @columns << { :name => col };
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
  
    class Column
      attr_accessor :name, :kind, :size, :constraints
      
      def initialize(opts={})
        @name = opts.delete(:name).to_s
        @kind = opts.delete(:kind).to_sym
        @size = opts.delete(:size).to_s
        @constraints = opts.dup
      end
      
      def geospatial?
        false
      end
      
      def to_sql
        Mystic.adapter.column_sql(self)
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