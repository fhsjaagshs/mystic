#!/usr/bin/env ruby

require "mystic"

module Mystic
  module SQL
    class Table
      def drop_index(idx_name)
        self << Mystic::SQL::Operation.new(
          :kind => :drop_index,
          :index_name => idx_name.to_s,
          :table_name => self.name.to_s
        )
      end
    
      def rename_column(oldname, newname)
        self << Mystic::SQL::Operation.new(
          :kind => :rename_column,
          :table_name => self.name.to_s,
          :old_col_name => oldname.to_s,
          :new_col_name => newname.to_s
        )
      end
    
      def rename(newname)
        self << Mystic::SQL::Operation.new(
          :kind => :rename_table,
          :old_name => self.name.to_s,
          :new_name => newname.to_s,
					:callback => lambda { self.name = newname }
        )
      end
    
      def drop_columns(*col_names)
        self << Mystic::SQL::Operation.new(
          :kind => :drop_columns,
          :table_name => self.name.to_s,
          :column_names => col_names.map(&:to_s)
        )
      end
      
      #
      ## Column DSL
      #
      
      def column(col_name, kind, opts={})
        self << Column.new({
          :name => col_name,
          :kind => kind.to_sym
        }.merge(opts || {}))
      end

      def geometry(col_name, kind, srid, opts={})
        self << SpatialColumn.new({
          :name => col_name,
          :geom_kind => kind,
          :geom_srid => srid
        }.merge(opts || {}))
      end
      
      def index(*cols)
        opts = cols.delete_at(-1) if cols.last.is_a?(Hash)
        opts ||= {}
        opts[:columns] = cols
        self << Index.new({ :tblname => @name }.merge(opts))
      end
      
      def method_missing(meth, *args, &block)
        column(args[0], meth.to_s, args[1])
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
			q.map! &:to_sql
			
			begin
				q.each{ |obj| "EXPLAIN #{Mystic.execute(obj)}" }
			rescue StandardError => e
				raise Error, e.message
			end
			
			q.each{ |obj| Mystic.execute(obj) }
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
      table = Mystic::SQL::Table.new(name, true)
      yield table
      queue table
    end
    
    def alter_table(name)
			raise ArgumentError, "No block provided, a block is required to alter a table." unless block_given?
      table = Mystic::SQL::Table.new(name, false)
      yield table
      queue table
    end
    
    def drop_table(name)
			queue Mystic::SQL::Operation.new(
							:kind => :drop_table,
							:table_name => name.to_s
						)
    end
		
		def drop_index(*args)
			queue Mystic::SQL::Operation.new(
       				:index_name => args[0],
        			:name => args[1]
      			)
		end
    
    def create_ext(extname)
			queue Mystic::SQL::Operation.new(
       				:kind => :create_extension,
        			:name => extname.to_s
      			)
    end
    
    def drop_ext(extname)
			queue Mystic::SQL::Operation.new(
        			:kind => :drop_extension,
        			:name => extname.to_s
      			)
    end
    
    def create_view(name, sql)
			queue Mystic::SQL::Operation.new(
							:kind => :create_view,
							:view_name => name.to_s,
							:view_sql => sql.to_s
						)
    end
    
    def drop_view(name)
			queue Mystic::SQL::Operation.new(
							:kind => :drop_view,
			    		:view_name => name.to_s
						)
    end
  end
end