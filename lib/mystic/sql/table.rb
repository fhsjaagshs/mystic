#!/usr/bin/env ruby

module Mystic
  module SQL
    class Table
      attr_reader :name
      attr_accessor :columns,
										:indeces,
										:operations,
										:inherits,
                    :tablespace
										
			def self.create opts={}
				new true, opts
			end
			
			def self.alter opts={}
				new false, opts
			end
      
      def initialize is_create=true, opts={}
				@is_create = is_create
        @name = (opts[:name] || opts["name"]).to_sym
        @inherits = opts[:inherits] || opts["inherits"]
        @tablespace = opts[:tablespace] || opts["tablespace"]
        @columns = []
        @indeces = []
        @operations = []
        raise ArgumentError, "Argument 'name' is invalid." if @name.empty?
      end
			
			def create?
				@is_create
			end
    
      def << obj
        case obj
        when Column then @columns << obj
        when Index then @indeces << obj
        when String then @sqls << obj
        else raise ArgumentError, "Argument is not a Mystic::SQL::Column, Mystic::SQL::Operation, or Mystic::SQL::Index." end
      end
    
      def to_s
        raise ArgumentError, "Table cannot have zero columns." if @columns.empty?
  			sql = []
			
  			if create?
  				tbl = []
  				tbl << "CREATE TABLE #{@name} (#{@columns.map(&:to_s)*","})"
  				tbl << "INHERITS #{@inherits}" if @inherits
  				tbl << "TABLESPACE #{@tablespace}" if @tablespace
  				sql << tbl*' '
  			else
  				sql << "ALTER TABLE #{@name} #{@columns.map { |c| "ADD COLUMN #{c.to_s}" }*', ' }"
  			end
      
  			sql.push(*@indeces.map(&:to_s)) unless @indeces.empty?
  	    sql.push(*@sqls.map(&:to_s)) unless @operations.empty?
  			sql*'; '
      end

			#
			## Operation DSL
			#
			
      def drop_index idx_name
        self << "DROP INDEX #{idx_name}"
      end
    
      def rename_column oldname, newname
				raise Mystic::SQL::Error, "Cannot rename a column on a table that doesn't exist." if create?
        self << "ALTER TABLE #{table_name} RENAME COLUMN #{old_name} TO #{new_name}"
      end
    
      def rename newname
				raise Mystic::SQL::Error, "Cannot rename a table that doesn't exist." if create?
        self << "ALTER TABLE #{table_name} RENAME TO #{newname}"
        @name = newname
      end
    
      def drop_columns *col_names
				raise Mystic::SQL::Error, "Cannot drop a column(s) on a table that doesn't exist." if create?
        self << "ALTER TABLE #{table_name} #{col_names.map { |c| "DROP COLUMN #{c.to_s}" }*', ' }"
      end
      
      #
      ## Column DSL
      #
      
      # MIXED_ARGS
      def column col_name, type, *opts
        self << Mystic::SQL::Column.new({
          :name => col_name,
          :type => type
        }.merge(opts.unify_args))
      end
      
      # MIXED_ARGS
      def geometry col_name, geom_type, srid, *opts
        column col_name, :geometry, :geom_type => type, :geom_srid => srid
      end
      
      def index *cols
        opts = cols.last.is_a? Hash ? cols.last : {}
        opts[:columns] = cols[0..-2]
				opts[:table_name] = @name
        self << Mystic::SQL::Index.new(opts)
      end
      
      def method_missing meth, *args, &block
        return super if args.empty?
        column args[0], meth, *args[1..-1]
      end
    end
  end
end