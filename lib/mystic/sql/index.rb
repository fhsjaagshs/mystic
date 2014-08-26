#!/usr/bin/env ruby

module Mystic
  module SQL
    class Index
      attr_accessor :name, # Symbol or string
										:table_name, # Symbol or string
										:type, # Symbol
										:unique, # TrueClass/FalseClass
										:columns, # Array of Strings
										:opts # Hash, see below
      
      INDEX_TYPES = [
        :btree,
        :hash,
        :gist,
        :spgist,
        :gin
      ].freeze
      
			# opts
			# It's a Hash that represents options
      #
			# Key => Value (type)
			# :fillfactor => A value in the range 10..100 (Integer)
			# :fastupdate => true/false (TrueClass/FalseClass)
			# :concurrently => true/false (TrueClass/FalseClass)
			# :tablespace => The name of the desired tablespace (String)
			# :buffering => :on/:off/:auto (Symbol)
			# :concurrently => true/false (TrueClass/FalseClass)
			# :where => The conditions for including entries in your index, same as SELECT * FROM table WHERE ____ (String)
			
      def initialize opts={}
				opts.symbolize!
				raise ArgumentError, "Missing table_name." unless opts.member? :table_name
				raise ArgumentError, "Indeces need columns or else what's the point?" unless opts.member? :columns
        @name = opts.delete(:name).to_sym if opts.member? :name
        @table_name = opts.delete(:table_name).to_sym
        @type = (opts.delete(:type) || :btree).to_s.downcase.to_sym
				@unique = opts.delete :unique || false
        @columns = opts.delete(:columns).symbolize rescue []
				@opts = opts
      end
      
      # can accept shit other than columns like
      # box(location,location)
      def << col
        case col
        when Column then @columns << col.name.to_s
        when String then @columns << col
        else raise ArgumentError, "Column must be a String or a Mystic::SQL::Column" end
      end

			def method_missing(meth, *args, &block)
				return @opts[meth] if @opts.member? meth
				nil
			end
      
      def to_s
  			storage_params = opts.subhash :fillfactor, :buffering, :fastupdate
			
  			sql = []
  			sql << "CREATE"
  			sql << "UNIQUE" if unique
  			sql << "INDEX"
  			sql << "CONCURENTLY" if concurrently
  		  sql << name unless name.nil?
  		  sql << "ON #{table_name}"
  			sql << "USING #{type}" if INDEX_TYPES.include? type
  			sql << "(#{columns.map(&:to_s).join ',' })"
  			sql << "WITH (#{storage_params.sqlize})" unless storage_params.empty?
  			sql << "TABLESPACE #{tablespace}" unless tablespace.nil?
  			sql << "WHERE #{where}" unless where.nil?
  			sql*' '
      end
    end
  end
end