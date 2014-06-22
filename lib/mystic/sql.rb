#!/usr/bin/env ruby

module Mystic
  module SQL
		Error = Class.new(StandardError)
		
    class SQLObject
      def to_sql
        Mystic.adapter.serialize_sql obj
      end
      
      alias_method :to_s, :to_sql
    end
    
    class Index < SQLObject
      attr_accessor :name, # Symbol or string
										:table_name, # Symbol or string
										:type, # Symbol
										:unique, # TrueClass/FalseClass
										:columns, # Array of Strings
										:opts # Hash, see below
      
			# opts
			# It's a Hash that represents options
			#
			# MYSQL ONLY
			# Key => Value (type)
			# :comment => A string that's up to 1024 chars (String)
			# :algorithm => The algorithm to use (Symbol)
			# :lock => The lock to use (Symbol)
			#
			# POSTGRES ONLY
			# Key => Value (type)
			# :fillfactor => A value in the range 10..100 (Integer)
			# :fastupdate => true/false (TrueClass/FalseClass)
			# :concurrently => true/false (TrueClass/FalseClass)
			# :tablespace => The name of the desired tablespace (String)
			# :buffering => :on/:off/:auto (Symbol)
			# :concurrently => true/false (TrueClass/FalseClass)
			# :where => The conditions for including entries in your index, same as SELECT * FROM table WHERE ____ (String)
			
      def initialize(opts={})
				opts.symbolize!
				raise ArgumentError, "Indeces need a table_name or else what's the point?." unless opts.member? :table_name
				raise ArgumentError, "Indeces need columns or else what's the point?" unless opts.member? :columns
        @name = opts.delete(:name).to_sym if opts.member? :name
        @table_name = opts.delete(:table_name).to_sym
        @type = (opts.delete :type || :btree).to_s.downcase.to_sym
				@unique = opts.delete :unique || false
        @columns = opts.delete(:columns).symbolize rescue []
				@opts = opts
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
			
			def method_missing(meth, *args, &block)
				return @opts[meth] if @opts.member? meth
				nil
			end
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
      attr_accessor :geom_kind,
										:geom_srid
      
      def initialize(opts={})
        super opts
        @geom_kind = opts[:geom_kind]
        @srid = opts[:geom_srid]
      end
      
      def geospatial?
        true
      end
    end
    
    class Table < SQLObject
      attr_reader :name
      attr_accessor :columns,
										:indeces,
										:operations,
										:opts
										
			def self.create(opts={})
				new true,opts
			end
			
			def self.alter(opts={})
				new false,opts
			end
      
      def initialize(is_create=true, opts={})
				@is_create = is_create
				@opts = opts.symbolize
        @columns = []
        @indeces = []
        @operations = []
				
        @name = @opts.delete(:name).to_s
        raise ArgumentError, "Argument 'name' is invalid." if @name.empty?
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
			
			def method_missing(meth, *args, &block)
				return @opts[meth] if @opts.member? meth
				super
			end
    end
    
    class Operation < SQLObject
			attr_reader :kind,
									:callback
			
      def initialize(kind, opts={})
				@opts = opts.dup
				@callback = @opts.delete :callback
				@kind = kind
      end
      
      def method_missing(meth, *args, &block)
				@opts[meth.to_s.to_sym] rescue nil
      end
			
			def self.method_missing(meth, *args, &block)
				#new args[0], args[1]
				new meth, args[0]
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