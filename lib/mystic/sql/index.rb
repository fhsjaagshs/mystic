#!/usr/bin/env ruby

module Mystic
  module SQL
    class Index
      attr_accessor :name, # Symbol or String
										:table_name, # Symbol or String
										:type, # Symbol
										:unique, # true/false
										:columns, # Array of Symbols
                    :fillfactor, # Integer in (10..100)
                    :fastupdate, # true/false
                    :concurrently, # true/false
                    :tablespace, # Symbol
                    :buffering, # :on, :off, :auto
                    :where # String
      
      def initialize params={}
        opts = params.symbolize
				raise ArgumentError, "Missing table_name." unless opts.key? :table_name
        name = opts[:name].to_sym if opts.key? :name
        table_name = (opts[:table_name] || "").to_sym
				@unique = opts[:unique] == true
        @columns = opts[:columns].map { |c| c.to_s.to_sym rescue nil }.compact
        @fastupdate = (opts[:fastupdate] || true) == true
        @concurrently = (opts[:concurrently] || false) == true
        @tablespace = opts[:tablespace].to_sym
        @where = opts[:where].to_s
        type = (opts[:type] || :btree).to_s.downcase.to_sym
        fillfactor = opts[:fillfactor].to_i
        buffering = opts[:buffering] || :auto
        
        raise ArgumentError, "Indeces must contain at least one column." if @columns.empty?
      end
      
      def buffering= v
        raise ArgumentError, "Index buffering option must either be :on, :off, or :auto"  unless [:on, :off, :auto].include? v.to_s.to_sym
        @buffering = v.to_s.to_sym
      end
      
      def fillfactor= v
        raise ArgumentError, "Index fill factor must be in the range 10..100" unless (10..100).include? v
        @fillfactor = v.to_i
      end
      
      def type= v
        raise ArgumentError, "Index type must either be :btree, :hash, :gist, :spgist, :gin." unless INDEX_TYPES.include? @type
        @type = v.to_s.to_sym
      end
      
      def name= v
        raise ArgumentError, "Index name cannot be nil or empty." if v.nil? || v.empty?
        @name = v.to_s.to_sym
      end
      
      def table_name= v
        raise ArgumentError, "An index's table name cannot be nil or empty." if v.nil? || v.empty?
        @table_name = v.to_s.to_sym
      end

      def << col
        case col
        when Column then @columns << col.name.to_sym
        else @columns << col.to_s.to_sym end
      end
      
      def to_s
        storage_params = {
          :fillfactor => @fillfactor,
          :buffering => @buffering,
          :fastupdate => @fastupdate
        }.reject { |k,v| v.nil? }

  			sql = []
  			sql << "CREATE"
  			sql << "UNIQUE" if @unique
  			sql << "INDEX"
  			sql << "CONCURENTLY" if @concurrently
  		  sql << @name.dblquote
  		  sql << "ON #{@table_name.dblquote}"
  			sql << "USING #{@type.escape}" if INDEX_TYPES.include? @type
  			sql << "(#{@columns.map(&:sqlize)*',' })"
  			sql << "WITH (#{storage_params.sqlize})" unless storage_params.empty?
  			sql << "TABLESPACE #{@tablespace.dblquote}" if @tablespace
  			sql << "WHERE #{@where}" if @where
  			sql*' '
      end
    end
  end
end