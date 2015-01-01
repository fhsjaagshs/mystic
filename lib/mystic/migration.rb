#!/usr/bin/env ruby

module Mystic
  class Migration
		IrreversibleError = Class.new StandardError
    
		def initialize
      @sql = []
			@irreversible = false
		end
    
		def migrate
      up()
      _exec_loaded_sql
		end
		
		def rollback
      raise IrreversibleError, "Impossible to roll back an irreversible migration." if irreversible?
      down()
      _exec_loaded_sql
		end
    
    def _exec_loaded_sql
      begin
        Mystic.execute "SAVEPOINT #{self.class}"
        Mystic.execute @sql.join ''
      rescue
        Mystic.execute "ROLLBACK TO SAVEPOINT #{self.class}"
      else
        Mystic.execute "RELEASE SAVEPOINT #{self.class}"
      ensure
        @sql.clear
      end
    end
    
		#
		# DSL
		#
    
		def irreversible!
			@irreversible = true
		end
		
		def irreversible?
			@irreversible
		end
    
		# All migration SQL goes through here
    def execute obj
			@sql << obj.to_s.terminate
    end

    def transation
      execute "BEGIN"
      yield
      execute "COMMIT"
    end

    def create_table name
      t = Mystic::SQL::Table.create :name => name
      yield t
      execute t
    end
    
    def alter_table name
      t = Mystic::SQL::Table.alter :name => name
      yield t
      execute t
    end
    
    # MIXED_ARGS
    def drop_table name, *opts
      opts = opts.unify_args
			irreversible!
      sql = []
      sql << "DROP TABLE"
      sql << name.to_sym.sqlize
      sql << "CASCADE" if opts[:cascade] == true
      sql << "RESTRICT" if opts[:restrict] == true
      execute sql*' '
    end
		
		def drop_index idx_name
      execute "DROP INDEX #{idx_name.to_sym.sqlize}"
		end
    
    def create_ext extname
      execute "CREATE EXTENSION \"#{extname.to_sym.sqlize}\""
    end
    
    def drop_ext extname
      execute "DROP EXTENSION \"#{extname.to_sym.sqlize}\""
    end
    
    def create_view name, sql
      execute "CREATE VIEW #{name.to_sym.sqlize} AS #{sql}"
    end
    
    def drop_view name
      execute "DROP VIEW #{name.to_sym.sqlize}"
    end
  end
end