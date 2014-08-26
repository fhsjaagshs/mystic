#!/usr/bin/env ruby

module Mystic
  module SQL
    class Table
      attr_reader :name
      attr_accessor :columns,
										:indeces,
										:operations,
										:opts
										
			def self.create opts={}
				new true, opts
			end
			
			def self.alter opts={}
				new false, opts
			end
      
      def initialize is_create=true, opts={}
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
    
      def << obj
        case obj
        when Column then @columns << obj
        when Index then @indeces << obj
        when Operation then @operations << obj
        when String then @operations << obj
        else raise ArgumentError, "Argument is not a Mystic::SQL::Column, Mystic::SQL::Operation, or Mystic::SQL::Index." end
      end
    
      def to_s
        raise ArgumentError, "Table cannot have zero columns." if @columns.empty?
  			sql = []
			
  			if create?
  				tbl = []
  				tbl << "CREATE TABLE #{name} (#{columns.map(&:to_s)*","})"
  				tbl << "INHERITS #{opts[:inherits]}" if opts[:inherits]
  				tbl << "TABLESPACE #{opts[:tablespace]}" if opts[:tablespace]
  				sql << tbl*' '
  			else
  				sql << "ALTER TABLE #{name} #{columns.map{ |c| "ADD COLUMN #{c.to_s}" }*', ' }"
  			end
      
  			sql.push(*indeces.map(&:to_s)) unless indeces.empty?
  	    sql.push(*operations.map(&:to_s)) unless operations.empty?
  			sql*'; '
      end

			#
			## Operation DSL
			#
			
      def drop_index idx_name
				raise Mystic::SQL::Error, "Cannot drop an index on a table that doesn't exist." if create?
        self << "DROP INDEX #{idx_name}"
      end
    
      def rename_column oldname, newname
				raise Mystic::SQL::Error, "Cannot rename a column on a table that doesn't exist." if create?
        self << "ALTER TABLE #{table_name} RENAME COLUMN #{old_name} TO #{new_name}"
      end
    
      def rename newname
				raise Mystic::SQL::Error, "Cannot rename a table that doesn't exist." if create?
        self << "ALTER TABLE #{table_name} RENAME TO #{newname}"
        self.name = newname
      end
    
      def drop_columns *col_names
				raise Mystic::SQL::Error, "Cannot drop a column(s) on a table that doesn't exist." if create?
        self << "ALTER TABLE #{table_name} #{col_names.map { |c| "DROP COLUMN #{c.to_s}" }*', ' }"
      end
      
      #
      ## Column DSL
      #
      
      def column col_name, kind, opts={}
        self << Mystic::SQL::Column.new({
          :name => col_name,
          :kind => kind.to_sym
        }.merge(opts || {}))
      end

      def geometry col_name, kind, srid, opts={}
				self << Mystic::SQL::Column.new({
          :name => col_name,
					:kind => :geometry,
          :geom_kind => kind,
          :geom_srid => srid
        }.merge(opts || {}))
      end
      
      def index *cols
        opts = cols.delete_at -1 if cols.last.is_a? Hash
        opts ||= {}
        opts[:columns] = cols
				opts[:table_name] = @name
        self << Mystic::SQL::Index.new(opts)
      end
      
      def method_missing meth, *args, &block
				return column args[0], meth.to_s, args[1] if args.count > 0
				super
      end
    end
  end
end