#!/usr/bin/env ruby

module Mystic
  module SQL
    class Index
      attr_accessor :name, # Symbol or String
										:table_name, # Symbol or String
										:type, # Symbol
										:unique, # true/false
										:columns, # Array of Strings
                    :fillfactor, # Integer in (10..100)
                    :fastupdate, # true/false
                    :concurrently, # true/false
                    :tablespace, # String
                    :buffering, # :on, :off, :auto
                    :where # String
      
      INDEX_TYPES = [
        :btree,
        :hash,
        :gist,
        :spgist,
        :gin
      ].freeze
      
      def initialize params={}
        opts = params.symbolize
				raise ArgumentError, "Missing table_name." unless opts.key? :table_name
        @name = opts[:name].to_sym if opts.key? :name
        @table_name = opts[:table_name].to_sym
        @type = (opts[:type] || :btree).to_s.downcase.to_sym
				@unique = opts[:unique] == true
        @columns = opts[:columns].symbolize rescue []
        @fillfactor = opts[:fillfactor].to_i
        @fastupdate = (opts[:fastupdate] || true) == true
        @concurrently = (opts[:concurrently] || false) == true
        @tablespace = opts[:tablespace].to_s
        @buffering = opts[:buffering] || :auto
        @where = opts[:where].to_s
        
        raise ArgumentError, "Indeces must contain more than one column." if @columns.empty?
        raise ArgumentError, "Index buffering option must either be :on, :off, or :auto" unless [:on, :off, :auto].include? @buffering
        raise ArgumentError, "Index fill factor must be in the range 10..100" unless (10..100).include? @fillfactor
        raise ArgumentError, "Index type must either be :btree, :hash, :gist, :spgist, :gin." unless INDEX_TYPES.include?(@type)
      end
      
      # Accepts a String, Symbol, or a Mystic::SQL::Index
      def << col
        case col
        when Column then @columns << col.name.to_s
        else col.to_s end
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
  		  sql << @name unless @name.nil?
  		  sql << "ON #{@table_name}"
  			sql << "USING #{type}" if INDEX_TYPES.include? @type
  			sql << "(#{@columns.map(&:to_s).join ',' })"
  			sql << "WITH (#{storage_params.sqlize})" unless storage_params.empty?
  			sql << "TABLESPACE #{@tablespace}" if @tablespace
  			sql << "WHERE #{@where}" if @where
  			sql*' '
      end
    end
  end
end