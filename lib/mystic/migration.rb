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
    def execute(obj)
      obj = obj.to_sql if obj.is_a?(Mystic::SQL::SQLObject)
      Mystic.execute(obj)
    end

    def create_table(name)
      raise ArgumentError, "No block provided, blocks are required to create a table." unless block_given?
      table = Mystic::SQL::Table.new(name, true)
      yield(table)
      execute(table)
    end
    
    def alter_table(name)
      raise ArgumentError, "No block provided, blocks are required to create a table." unless block_given?
      table = Mystic::SQL::Table.new(name, false)
      yield(table)
      execute(table)
    end
    
    def drop_table(name)
			execute(
				Mystic::SQL::Operation.new(
					:kind => :drop_table,
					:table_name => name.to_s
				)
			)
    end
		
		def drop_index(*args)
			execute(
      	Mystic::SQL::Operation.new(
       		:index_name => args[0],
        	:name => args[1]
      	)
			)
		end
    
    def create_ext(extname)
			execute(
      	Mystic::SQL::Operation.new(
       		:kind => :create_extension,
        	:name => extname.to_s
      	)
			)
    end
    
    def drop_ext(extname)
			execute(
      	Mystic::SQL::Operation.new(
        	:kind => :drop_extension,
        	:name => extname.to_s
      	)
			)
    end
    
    def create_view(name, sql)
			execute(
				Mystic::SQL::Operation.new(
					:kind => :create_view,
					:view_name => name.to_s,
					:view_sql => sql.to_s
				)
			)
    end
    
    def drop_view(name)
			execute(
				Mystic::SQL::Operation.new(
					:kind => :drop_view,
			    :view_name => name.to_s
				)
			)
    end
  end
end