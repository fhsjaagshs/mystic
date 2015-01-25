#!/usr/bin/env ruby

module Mystic
  module SQL
    class Column
      attr_accessor :name, :type, :size, :primary_key, :references, :default, :check, :geom_kind, :geom_srid
      
      def initialize opts={}
        @name = (opts[:name] || opts["name"]).to_sym
        @type = (opts[:type] || opts["type"]).to_s.downcase.gsub('_',' ').to_sym
        @size = (opts[:size] || opts["size"]).to_i
        @unique = (opts[:unique] || opts["unique"]) == true
        @not_null = (opts[:not_null] || opts["not_null"]) == true
        @null = (opts[:null] || opts["null"]) == true
        @primary_key = (opts[:primary_key] || opts["primary_key"]) == true
        @references = opts[:references] || opts["references"]
        @default = opts[:default] || opts["default"]
        @check = opts[:check] || opts["check"]
        @geom_type = (opts[:geom_type] || opts["geom_type"]).to_s
        @geom_srid = (opts[:geom_srid] || opts["geom_srid"]).to_i
        
        raise ArgumentError, "You can't create a column without a name." if @name.nil? || @name.empty?
        raise ArgumentError, "You must provide a type for this column." if @type.nil? || @type.empty?
      end
      
      def type= v
        raise ArgumentError, "Type must either be a number or numeric" unless v.to_s.numeric?
        @v = v.to_s.to_i
      end
      
      def geospatial?; @type == :geometry; end
      def unique?; @unique; end
      
      def sqlize
        name.sqlize
      end
      
      def to_s
  			sql = []
  			sql << @name.to_s.dblquote
  			sql << @type.to_s
        if geospatial?
          sql << "(#{@geom_type.escape}, #{@geom_srid.to_s.escape})"
        else
          sql << "(#{@size.sqlize})" if @size > 0
        end
        sql << "NULL" if @null
        sql << "NOT NULL" if @not_null
  			sql << "UNIQUE" if @unique
  			sql << "PRIMARY KEY" if @primary_key
  			sql << "REFERENCES " + @references if @references
  			sql << "DEFAULT " + @default if @default
  			sql << "CHECK(#{@check.escape})" unless @check.nil? || @check.empty?
  			sql*" "
      end
    end
  end
end