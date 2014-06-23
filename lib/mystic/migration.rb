#!/usr/bin/env ruby

module Mystic
  module SQL
    class Table < SQLObject
      def drop_index(idx_name)
				raise Mystic::SQL::Error, "Cannot drop an index on a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.drop_index(
          :index_name => idx_name.to_s,
          :table_name => self.name.to_s
        )
      end
    
      def rename_column(oldname, newname)
				raise Mystic::SQL::Error, "Cannot rename a column on a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.rename_column(
          :table_name => self.name.to_s,
          :old_col_name => oldname.to_s,
          :new_col_name => newname.to_s
        )
      end
    
      def rename(newname)
				raise Mystic::SQL::Error, "Cannot rename a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.rename_table(
          :old_name => self.name.to_s,
          :new_name => newname.to_s,
					:callback => lambda { self.name = newname }
        )
      end
    
      def drop_columns(*col_names)
				raise Mystic::SQL::Error, "Cannot drop a column(s) on a table that doesn't exist." if create?
        self << Mystic::SQL::Operation.drop_columns(
          :table_name => self.name.to_s,
          :column_names => col_names.map(&:to_s)
        )
      end
      
      #
      ## Column DSL
      #
      
      def column(col_name, kind, opts={})
        self << Mystic::SQL::Column.new({
          :name => col_name,
          :kind => kind.to_sym
        }.merge(opts || {}))
      end

      def geometry(col_name, kind, srid, opts={})
				self << Mystic::SQL::Column.new({
          :name => col_name,
					:kind => :geometry,
          :geom_kind => kind,
          :geom_srid => srid
        }.merge(opts || {}))
      end
      
      def index(*cols)
        opts = cols.delete_at -1 if cols.last.is_a? Hash
        opts ||= {}
        opts[:columns] = cols
				opts[:table_name] = @name
        self << Mystic::SQL::Index.new(opts)
      end
      
      def method_missing(meth, *args, &block)
        column args[0], meth.to_s, args[1]
      end
    end
  end
  
  class Migration
		Error = Class.new(StandardError)
		IrreversibleError = Class.new(StandardError)

		def initialize
			@irreversible = false
		end
		
		def migrate
			exec_migration :up
		end
		
		def rollback
			exec_migration :down
		end
		
		# TODO: This is ugly... It needs cleaning up.
		def exec_migration(direction)
			direction = direction.to_sym
			raise ArgumentError, "Direction must be either :up or :down." if [:up, :down].include? direction
			raise IrreversibleError, "Impossible to roll back an irreversible migration." if direction == :down && irreversible?
			begin
				Mystic::SQL::Transaction.start
				method(direction).call
			rescue => e
				Mystic::SQL::Transaction.rollback
				puts "Error encountered, rolling back..."
				raise e
			else
				Mystic::SQL::Transaction.commit
			end
		end
		
		
		#
		# DSL
		#
		
    def execute(obj)
			Mystic.execute obj.to_s # to_sql isn't defined for strings, to_sql is aliased to to_s
    end
		
		def irreversible!
			@irreversible = true
		end
		
		def irreversible?
			@irreversible
		end

    def create_table(name)
      raise ArgumentError, "No block provided, a block is required to create a table." unless block_given?
      table = Mystic::SQL::Table.create :name => name
      yield table
      execute table
    end
    
    def alter_table(name)
			raise ArgumentError, "No block provided, a block is required to alter a table." unless block_given?
      table = Mystic::SQL::Table.alter :name => name
      yield table
      execute table
    end
    
    def drop_table(name)
			execute Mystic::SQL::Operation.drop_table(
				:table_name => name.to_s
			)
    end
		
		def drop_index(*args)
			execute Mystic::SQL::Operation.drop_index(
				:index_name => args[0],
				:table_name => args[1]
			)
		end
    
    def create_ext(extname)
			execute Mystic::SQL::Operation.create_ext(
				:name => extname.to_s
			)
    end
    
    def drop_ext(extname)
			execute Mystic::SQL::Operation.drop_ext(
				:name => extname.to_s
			)
    end
    
    def create_view(name, sql)
			execute Mystic::SQL::Operation.create_view(
				:name => name.to_s,
				:sql => sql.to_s
			)
    end
    
    def drop_view(name)
			execute Mystic::SQL::Operation.drop_view(
				:name => name.to_s
			)
    end
  end
end