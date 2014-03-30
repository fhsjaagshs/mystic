#!/usr/bin/env ruby

module Mystic
  class Table
    
    @sql_command = ""
    @columns = []
    
    def initialize(name)
      @name = name
      super
    end
    
    def string(name, opts={})
      column("VARCHAR", name, opts);
    end
    
    def integer(name, opts={})
      
    end
    
    def column(type, name, opts={})
      @columns << { :type => type, :name => name, :opts => opts }
    end
    
    def to_sql
      CREATE TABLE article (
          article_id bigserial primary key,
          article_name varchar(20) NOT NULL,
          article_desc text NOT NULL,
          date_added timestamp default NULL
      );
      
      column_strings = []
      
      @columns.each do |column|
        
        type = ""
        
        
        column_str = "#{column[:name]} #{type}(#{column[:opts][:length]})"
        
        # append options
        
        column[:opts].each do |key, value|
          case key
          when :not_null
            column_str << " NOT NULL"
          when :unique
            
          when :primary_key
            
          end
        end
        
        column_str << " "
        
        column_strings << column_str
      end
      
      "CREATE TABLE #{name} (#{column_strings.join(",")});"
    end
    
  end
    
  class Migration
    def create_table(name)
      table = Mystic::Table.new(name)
      yield(table) if block_given?
      Mystic.execute(table.to_sql)
    end
  end
end