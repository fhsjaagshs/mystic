#!/usr/bin/env ruby

module Mystic
  module SQL
		Error = Class.new(StandardError)
		
    class SQLObject
      def to_sql
				obj = self.dup
				obj.instance_variables.each do |vname|
					v = obj.instance_variable_get vname
					if v.is_a? Symbol
						obj.instance_variable_set vname,v.to_s
					end
				end
        Mystic.adapter.serialize_sql obj
      end
      
      alias_method :to_s, :to_sql
    end
    
    class Index < SQLObject
      attr_accessor :name, :tblname, :opts, :type, :unique, :using, :concurrently, :with, :columns, :tablespace
      
      def initialize(opts={})
        @name = opts[:name]
        @tblname = opts[:tblname]
        @type = opts[:type].to_sym || :btree # a string/symbol
        @unique = opts[:unique] # a boolean
        @concurrently = opts[:concurrently] # a boolean
        @with = opts[:with] # a hash (keys => { :fillfactor => 10..100, :fastupdate => true })
        @tablespace = opts[:tablespace]
        @columns = opts[:columns].map(&:to_sym) || []
      end
      
      # can accept shit other than columns like
      # box(location,location)
      def <<(col)
        case col
        when Column
          @columns << col.name.to_s
        when String
          @columns << col
        else
          raise ArgumentError, "Column must be a String or a Mystic::SQL::Column"
        end
      end

      alias_method :push, :<<
    end
  
    class Column < SQLObject
      attr_accessor :name, :kind, :size, :constraints
      
      def initialize(opts={})
        @name = opts.delete(:name).to_s
        @kind = opts.delete(:kind).to_sym
        @size = opts.delete(:size).to_s
        @constraints = opts
      end
      
      def geospatial?
        false
      end
    end
  
    class SpatialColumn < Column
      attr_accessor :geom_kind, :geom_srid
      
      def initialize(opts={})
        super(opts)
        @geom_kind = opts[:geom_kind]
        @srid = opts[:geom_srid]
      end
      
      def geospatial?
        true
      end
    end
    
    class Table < SQLObject
      attr_reader :name
      attr_accessor :columns, :indeces, :operations
      
      def initialize(name,is_create=true)
        @name = name.to_s
        raise ArgumentError, "Argument 'name' is invalid." if @name.nil? || @name.empty?
        @columns = []
        @indeces = []
        @operations = []
        @is_create = is_create
      end
			
			def create?
				@is_create
			end
    
      def <<(obj)
        case obj
        when Column
          @columns << obj
        when Index
          @indeces << obj
        when Operation
          @operations << obj
        else
          raise ArgumentError, "Argument is not a Mystic::SQL::Column, Mystic::SQL::Operation, or Mystic::SQL::Index."
        end
      end
    
      def to_sql
        raise ArgumentError, "Table cannot have zero columns." if @columns.empty?
        super
      end

      alias_method :push, :<<
    end
    
    class Operation < SQLObject
			attr_reader :kind, :callback
      def initialize(kind, opts={})
        @opts = opts
				@kind = kind
				@callback = opts[:callback]
      end
      
      def execute
        Mystic.execute to_sql
      end
      
      def method_missing(meth, *args, &block)
				@opts[meth.to_s.to_sym] rescue nil
      end
			
			def self.method_missing(meth, *args, &block)
				new args[0],args[1]
			end
    end
		
		class Raw < SQLObject
			def initialize(opts)
				@sql = opts[:sql]
			end
			
			def to_sql
				@sql
			end
		end
  end
end