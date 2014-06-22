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
        self << Mystic::SQL::SpatialColumn.new({
          :name => col_name,
					:kind => "geometry",
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

		def initialize
			@irreversible = false
			@direction = :neither
			@up_queue = []
			@down_queue = []
		end
		
		def migrate
			@direction = :up
			@up_queue.clear
			up
			exec_queue
		end
		
		def rollback
			@direction = :down
			@down_queue.clear
			down
			exec_queue
		end
		
		def exec_queue
			q = @direction == :up ? @up_queue : @down_queue

			q.map!(&:to_sql)
			
			Mystic.execute "BEGIN TRANSACTION"
			
			begin
				q.each{ |sql| Mystic.execute sql }
			rescue StandardError => e
				Mystic.execute "ROLLBACK"
				puts "Error encountered, rolling back..."
				raise Error, e.message
			end
			
			Mystic.execute "COMMIT"
			
			q.clear
		end
		
		def queue(obj)
			case @direction
			when :up
				@up_queue << obj
			when :down
				@down_queue << obj
			end
		end
		
		#
		# DSL
		#
		
    def execute(obj)
			queue Mystic::SQL::Raw.new :sql => obj.to_s
    end
		
		def ireversaible!
			@irreversible = true
		end

    def create_table(name)
      raise ArgumentError, "No block provided, a block is required to create a table." unless block_given?
      table = Mystic::SQL::Table.create :name => name
      yield table
      queue table
    end
    
    def alter_table(name)
			raise ArgumentError, "No block provided, a block is required to alter a table." unless block_given?
      table = Mystic::SQL::Table.alter :name => name
      yield table
      queue table
    end
    
    def drop_table(name)
			queue Mystic::SQL::Operation.drop_table(
				:table_name => name.to_s
			)
    end
		
		def drop_index(*args)
			queue Mystic::SQL::Operation.drop_index(
				:index_name => args[0],
				:table_name => args[1]
			)
		end
    
    def create_ext(extname)
			queue Mystic::SQL::Operation.create_ext(
				:name => extname.to_s
			)
    end
    
    def drop_ext(extname)
			queue Mystic::SQL::Operation.drop_ext(
				:name => extname.to_s
			)
    end
    
    def create_view(name, sql)
			queue Mystic::SQL::Operation.create_view(
				:name => name.to_s,
				:sql => sql.to_s
			)
    end
    
    def drop_view(name)
			queue Mystic::SQL::Operation.drop_view(
				:name => name.to_s
			)
    end
  end
end