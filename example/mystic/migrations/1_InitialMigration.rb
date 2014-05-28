#!/usr/bin/env ruby

require "mystic"

class InitialMigration < Mystic::Migration
  def up
    create_ext "uuid-ossp"

    create_table :users do |t|
      t.uuid :guid, :unique => true, :default => "uuid_generate_v4()"
      t.varchar :username, :size => 255
			t.text :name
      t.boolean :cool
      t.integer :likes
      t.text :bio
      t.text :drop_me
      t.text :drop_me_too
    end
    
    alter_table :users do |t|
			t.index "lower(name) DESC NULLS LAST" # instead of column name, you can pass custom SQL
      t.index :guid # single column index
			t.index :cool, :likes # multicolumn index
      t.drop_columns :drop_me, :drop_me_too
      t.rename_column :cool, :is_cool
      t.varchar :some_string, :size => 255 # adds a column
      t.rename :subscribers # rename the table to subscribers
    end
    
    execute "INSERT INTO subscribers (bio) VALUES ('A test string')"
    
    create_view :bios, "SELECT bio FROM subscribers" # create a view
  end
  
  def down
    drop_index :guid_idx
    drop_table :users
    drop_view :bios
    drop_ext "uuid-ossp"
  end
end