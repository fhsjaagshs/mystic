#!/usr/bin/env ruby

module Mystic  
  class Migration
		Error = Class.new(StandardError)
		IrreversibleError = Class.new(StandardError)

		def initialize
			@irreversible = false
			@sql = ""
		end
		
		def migrate
			exec_migration :up
		end
		
		def rollback
			exec_migration :down
		end
		
		# TODO: This is ugly... It needs cleaning up.
		def exec_migration(direction)
			@sql = ""
			
			direction = direction.to_sym
			
			raise ArgumentError, "Direction must be either :up or :down." unless [:up, :down].include? direction
			raise IrreversibleError, "Impossible to roll back an irreversible migration." if direction == :down && irreversible?
			
			execute Mystic::SQL::Operation.start_transaction
			method(direction).call
			execute Mystic::SQL::Operation.commit_transaction
			
			Mystic.adapter.execute @sql # bypass densification
		end
		
		
		#
		# DSL
		#
		
		# All migration SQL goes through here
    def execute(obj)
			@sql << obj.to_s.sql_terminate # to_sql isn't defined for strings, to_sql is aliased to to_s
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
    
    def drop_table(name, opts={})
			irreversible!
			execute Mystic::SQL::Operation.drop_table(
				:table_name => name.to_s,
				:cascade? => opts[:cascade]
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