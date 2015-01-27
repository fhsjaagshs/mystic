#!/usr/bin/env ruby

module Mystic
  module SQL
    class Index  
      FILLFACTOR_RANGE = (10..100).freeze
    	INDEX_TYPES = [:btree, :hash, :gist, :spgist, :gin].freeze
       
      def initialize params={}
        opts = params.symbolize.subhash([
          :fastupdate,
          :concurrently,
          :tablespace,
          :where,
          :type,
          :fillfactor,
          :buffering,
          :unique,
          :table,
          :columns,
          :name
        ]).each { |option,value| send (option.to_s + '=').to_sym, value }

        raise ArgumentError, "Indeces must contain at least one column." if columns.empty?
      end
      
      def unique?; @unique; end
      def concurrently?; @concurrently; end
      def fastupdate?; @fastupdate; end
      
      # Accept truthy/falsey values
      def unique= v; @unique = v ? true : false; end
      def concurrently= v; v.nil? ? false : (@concurrently = v ? true : false); end
      def fastupdate= v; v.nil? ? true : (@fastupdate = v ? true : false); end
      
      def columns; (columns = @columns) rescue []; end
      def columns= v;  @columns = v.compact.reject(&:empty?); end
      
      def name
        @name ||= ["index",table].push(*columns.map(&:sqlize).map { |c| c.start_with?('"') ? c[1..-2] : c }).join('_').to_sym
      end

      def name= v
        return (@name = nil) if v.nil?
        raise ArgumentError, "Index name must not be empty." if v.empty?
        raise TypeError, "Index name must be a Symbol." unless Symbol === v
        @name = v
      end
      
      def where; @where; end
      def where= v
        raise TypeError, ":where must be an integer" unless Integer === v || v.nil?
        @where = v
      end
      
      def buffering; @buffering; end
      def buffering= v
        raise ArgumentError, "Invalid buffering option: #{v}. Index buffering option must either be :on, :off, or :auto."  unless [:on, :off, :auto].include?(v) || v.nil?
        @buffering = v
      end
      
      def fillfactor; @fillfactor; end
      def fillfactor= v
        return (@fillfactor = nil) if v.nil?
        raise TypeError, "Fillfactor must be an Integer." unless Integer === v
        raise ArgumentError, "Invalid fill factor: #{v}. Index fill factor must be in the range #{FILLFACTOR_RANGE.inpect}" unless FILLFACTOR_RANGE.include? v
        @fillfactor = v
      end
      
      def tablespace; @tablespace; end
      def tablespace= v
        return (@tablespace = nil) if v.nil?
        raise TypeError, "Tablespace must be a Symbol." unless Symbol === v
        @tablespace = v
      end
      
      def type; @type; end
      def type= v
        return (@type = nil) if v.nil?
        raise TypeError, "Index type must be a Symbol." unless Symbol === v
        raise ArgumentError, "Invalid index type: #{v}. Index type must either be :btree, :hash, :gist, :spgist, or :gin." unless INDEX_TYPES.include? v
        @type = v
      end

      def table; @table; end
      def table= v
        raise ArgumentError, "Index table name must not be nil." if v.nil?
        raise ArgumentError, "Index table name must not be empty." if v.empty?
        raise TypeError, "Index table name must be a Symbol." unless Symbol === v
        @table = v
      end
      
      def to_s
        storage_params = {
          "fillfactor" => fillfactor,
          "buffering" => buffering,
          "fastupdate" => fastupdate
        }.reject { |k,v| v.nil? }
        
  			sql = []
  			sql << "CREATE"
  			sql << "UNIQUE" if unique?
  			sql << "INDEX"
  			sql << "CONCURENTLY" if concurrently?
  		  sql << name.sqlize
  		  sql << "ON #{table.sqlize}" if table_name
  			sql << "USING #{type.to_s.escape}" if type
  			sql << "(#{columns.map { |c| Symbol === c ? c.sqlize : c }.join(',')})"
  			sql << "WITH (#{storage_params.map { |k,v| k.escape + ' = ' + v.to_s.escape }*", "})" unless storage_params.empty?
  			sql << "TABLESPACE #{tablespace.sqlize}" if tablespace
  			sql << "WHERE #{where}" if where
        puts "----------------------\n" + sql*' '
  			sql*' '
      end
    end
  end
end
