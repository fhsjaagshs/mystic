#!/usr/bin/env ruby

require_relative "./lib/mystic"

# override for logging
module Mystic
  class << self
    def execute sql
      puts "SQL: \t#{sql}"
    end
  end
end

Mystic.connect :user => "nathaniel", :password => "", :dbname => "nathaniel", :port => 5432, :host => "localhost"

class Paws
  include Mystic::Model
  
  table :paws
  
  column :id
  column :name
  column :breed
  
#  Mystic.execute (sql :select, :asdf => "asdf")
end

Paws.select :id => "asdf"