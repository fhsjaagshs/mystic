#!/usr/bin/env ruby

require "mystic"

class InitialMigration < Mystic::Migration
  
  def up
    create_table :users do |t|
      t.varchar :guid, :size => 255, :unique => true
      t.varchar :username, :size => 255
      t.boolean :cool
      t.integer :likes
      t.text :bio
      t.text :drop_me
    end
    
    add_index :users, :guid_idx, :columns => [{:name => :guid, :order => :desc}]
    drop_columns :users, :drop_me
  end
  
  def down
    drop_index :guid_idx
    drop_table :users
  end
  
end