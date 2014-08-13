#!/usr/bin/env ruby

Dir.glob("./sql/**/*.rb", &method(:require))

module Mystic
  module SQL
		Error = Class.new StandardError
		
    class SQLObject
      def to_sql
        
      end
      
      alias_method :to_s, :to_sql
    end
  end
end