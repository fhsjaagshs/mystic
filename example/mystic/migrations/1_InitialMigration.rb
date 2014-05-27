#!/usr/bin/env ruby

require "mystic"

class InitialMigration < Mystic::Migration
  
  def up
    create_ext "uuid-ossp"

    create_table :users do |t|
      t.uuid :guid, :unique => true, :default => "uuid_generate_v4()"
      t.varchar :username, :size => 255
      t.boolean :cool
      t.integer :likes
      t.text :bio
      t.text :drop_me
      t.text :drop_me_too
    end
    
    alter_table :users do |t|
      t.index :guid, :order => :desc
      t.drop_columns :drop_me, :drop_me_too
      t.rename_column :cool, :is_cool
      t.varchar :some_string, :size => 255 # adds a column
      t.rename :users_table # rename the table
    end
    
    execute "INSERT INTO users (bio) VALUES ('A test string')"
    
    create_view :bios, "SELECT bio FROM users"
  end
  
  def down
    drop_index :guid_idx
    drop_table :users
    drop_view :bios
    drop_ext "uuid-ossp"
  end
end