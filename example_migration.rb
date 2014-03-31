#!/usr/bin/env ruby

require "mystic"

class InitialMigration < Mystic::Migration
  
  def up
    create_table :users do |t|
      t.varchar :guid, :length => 255
      t.boolean :cool
      t.integer :likes
      t.text :bio
    end
  end
  
  def down
    drop_table :users
  end
  
end