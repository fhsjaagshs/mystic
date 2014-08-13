#!/usr/bin/env ruby

module Mystic
  module SQL
    class Column < SQLObject
      attr_accessor :name, :kind, :size, :constraints, :geom_kind, :geom_srid
      
      def initialize(opts={})
        @name = opts.delete(:name).to_s
        @kind = opts.delete(:kind).to_sym
        @size = opts.delete(:size).to_s if opts.member? :size
        @geom_kind = opts.delete(:geom_kind)
        @geom_srid = opts.delete(:geom_srid).to_i
        @constraints = opts
      end
      
      def geospatial?
				@geom_kind && @geom_srid
      end
      
      def to_sql
  			sql = []
  			sql << name
  			sql << kind.downcase
  			sql << "(#{size})" if size && !size.empty? && !geospatial?
  			sql << "(#{geom_kind}, #{geom_srid})" if geospatial?
        sql << (constraints[:null] ? "NULL" : "NOT NULL") if constraints.member?(:null)
  			sql << "UNIQUE" if constraints[:unique]
  			sql << "PRIMARY KEY" if constraints[:primary_key]
  			sql << "REFERENCES " + constraints[:references] if constraints.member?(:references)
  			sql << "DEFAULT " + constraints[:default] if constraints.member?(:default)
  			sql << "CHECK(#{constraints[:check]})" if constraints.member?(:check)
  			sql*" "
      end
    end
  end
end