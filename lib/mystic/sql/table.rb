#!/usr/bin/env ruby

module Mystic
  module SQL
    Error = Class.new StandardError
    class Table
      attr_reader :name
      attr_accessor :columns,
										:indeces,
										:operations,
										:inherits,
                    :tablespace
										
			def self.create opts={}; new true, opts; end
			def self.alter opts={}; new false, opts; end
			def create?; @is_create; end
      
      def initialize is_create=true, opts={}
				@is_create = is_create
        @name = (opts[:name] || opts["name"]).to_sym rescue nil
        @inherits = (opts[:inherits] || opts["inherits"]).to_sym rescue nil
        @tablespace = (opts[:tablespace] || opts["tablespace"]).to_sym rescue nil
        @columns = []
        @indeces = []
        @operations = []
        raise ArgumentError, "Argument 'name' is invalid." if @name.empty?
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
  				tbl << "CREATE TABLE #{@name.sqlize} (#{@columns.map { |c| c.to_s }*","})"
  				tbl << "INHERITS #{@inherits.sqlize}" unless @inherits.nil?
  				tbl << "TABLESPACE #{@tablespace.sqlize}" unless @tablespace.nil?
  				sql << tbl*' '
  			else
  				sql << "ALTER TABLE #{@name.sqlize} #{@columns.map { |c| "ADD COLUMN #{c.to_s}" }*', ' }"
  			end
      
  			sql.push(*@indeces.map(&:to_s)) unless @indeces.empty?
  	    sql.push(*@sqls.map(&:to_s)) unless @operations.empty?
  			sql*'; '
      end

			#
			## Operation DSL
			#
			
      def drop_index idx
        raise ArgumentError, "No index name provided." if idx.nil? || idx.empty?
        self << "DROP INDEX #{idx.to_sym.sqlize}"
      end
    
      def rename_column oldname, newname
        raise Mystic::SQL::Error, "Cannot rename a column on a table that doesn't exist." if create?
        raise ArgumentError, "No original name of the column provided." if oldname.nil? || oldname.empty?
        raise ArgumentError, "No new name for the column provided." if newname.nil? || newname.empty?
        self << "ALTER TABLE #{table_name.to_sym.sqlize} RENAME COLUMN #{old_name.to_sym.sqlize} TO #{new_name.to_sym.sqlize}"
      end
    
      def rename newname
				raise Mystic::SQL::Error, "Cannot rename a table that doesn't exist." if create?
        raise ArgumentError, "No new name for the table provided." if oldname.nil? || oldname.empty?
        self << "ALTER TABLE #{table_name.to_sym.sqlize} RENAME TO #{newname.to_sym.sqlize}"
        @name = newname
      end
    
      def drop_columns *col_names
				raise Mystic::SQL::Error, "Cannot drop a column(s) on a table that doesn't exist." if create?
        raise ArgumentError, "No columns to drop." if oldname.nil? || oldname.empty?
        self << "ALTER TABLE #{table_name.to_sym.sqlize} #{col_names.map { |c| "DROP COLUMN #{c.to_sym.sqlize}" }*', ' }"
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
        define_singleton_method meth do |*args|
          column args[0], meth, *args[1..-1]
        end
        send meth, *args, &block
      end
    end
  end
end