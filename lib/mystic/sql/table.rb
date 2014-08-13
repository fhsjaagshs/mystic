#!/usr/bin/env ruby

module Mystic
  module SQL
    class Table < SQLObject
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
        else raise ArgumentError, "Argument is not a Mystic::SQL::Column, Mystic::SQL::Operation, or Mystic::SQL::Index." end
      end
    
      def to_sql
        raise ArgumentError, "Table cannot have zero columns." if @columns.empty?
  			sql = []
			
  			if create?
  				tbl = []
  				tbl << "CREATE TABLE #{name} (#{columns.map(&:to_sql)*","})"
  				tbl << "INHERITS #{inherits}" if inherits
  				tbl << "TABLESPACE #{tablespace}" if tablespace
  				sql << tbl*' '
  			else
  				sql << "ALTER TABLE #{name} #{columns.map{ |c| "ADD COLUMN #{c.to_sql}" }*', ' }"
  			end
      
  			sql.push(*indeces.map(&:to_sql)) unless indeces.empty?
  	    sql.push(*operations.map(&:to_sql)) unless operations.empty?
  			sql*'; '
      end

			#
			## Operation DSL
			#
			
      def drop_index idx_name
				raise Mystic::SQL::Error, "Cannot drop an index on a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.drop_index(
          :index_name => idx_name.to_s,
          :table_name => self.name.to_s
        )
      end
    
      def rename_column oldname, newname
				raise Mystic::SQL::Error, "Cannot rename a column on a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.rename_column(
          :table_name => self.name.to_s,
          :old_name => oldname.to_s,
          :new_name => newname.to_s
        )
      end
    
      def rename newname
				raise Mystic::SQL::Error, "Cannot rename a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.rename_table(
          :old_name => self.name.dup.to_s,
          :new_name => newname.to_s,
					:callback => lambda { self.name = newname }
        )
      end
    
      def drop_columns *col_names
				raise Mystic::SQL::Error, "Cannot drop a column(s) on a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.drop_columns(
          :table_name => self.name.to_s,
          :column_names => col_names.map(&:to_s)
        )
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
				return @opts[meth] if @opts.member?(meth)
				super
      end
    end
  end
end