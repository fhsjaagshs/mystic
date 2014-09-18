#!/usr/bin/env ruby

module Mystic
  module SQL
    class Column
      attr_accessor :name, :type, :size, :primary_key, :references, :default, :check, :geom_kind, :geom_srid
      
      def initialize opts={}
        @name = (opts[:name] || opts["name"].to_sym
        @type = (opts[:type] || opts["type"]).to_sym
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
      
      def geospatial?
        @type == :geometry
      end
      
      def unique?
        @unique
      end
      
      def to_s
  			sql = []
  			sql << @name.to_s
  			sql << @type.downcase
  			sql << "(#{@size})" if @size > 0 && !geospatial?
  			sql << "(#{@geom_type}, #{@geom_srid})" if geospatial?
        sql << "NULL" if @null
        sql << "NOT NULL" if @not_null
  			sql << "UNIQUE" if @unique
  			sql << "PRIMARY KEY" if @primary_key
  			sql << "REFERENCES " + @references if @references
  			sql << "DEFAULT " + @default if @default
  			sql << "CHECK(#{@check})" if @check
  			sql*" "
      end
    end
  end
end