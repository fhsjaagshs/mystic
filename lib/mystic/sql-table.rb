#!/usr/bin/env ruby

module Mystic
  class SQLColumn
    
    def initialize(opts={})
      @name = opts[:name].to_s
      @kind = opts[:kind].to_s
      @attributes = {}
    end
    
    def initialize(name, kind)
      
    end
    
    def [](key)
      @attributes[key]
    end
    
    def []=(key, value)
      # Mystic.adapter.handle_attribute() will raise exceptions if the attribute is not supported by the database
      Mystic.adapter.handle_attribute(attribute, value)
    end
    
    def to_sql
      # generate sql
    end
  end
  
  class SQLTable
    
    def initialize(name)
      @name = name
      @columns = []
    end
    
    def <<(column)
      @columns << column
    end
    
    def to_sql
      cols_sql = @columns.inject do |col_string, column|
        col_string << ","+column.to_sql
      end
      "CREATE TABLE #{@name} (#{cols_sql})"
    end
  end
end