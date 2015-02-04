Mystic
===

Clean & extensible Postgres access compatible with Rails configuration.

Philosophy
-

I'm a person who likes to build his own tools rather than fight with other people's. Refusing to fight with other people's code frees enough time for me to both build a tool and accomplish what I set out to accomplish.

Mystic is as abstract, generic, and unopinionated possible. Huge parts of it can be easily reconfigured.

For example, Mystic provides a config object at `Mystic.config` that reads a Rails database.yml, but it doesn't force you to use it: you can always write your own config class.

Configuring Mystic
-

First, you need to create a folder for migrations

    $ cd your_project
    $ mkdir -p mystic/migrations

Optional Config
-

Without changing this configuration, Mystic will work in the same environment Rails will.

Nonetheless, modifying the configuration code is as easy as creating a subclass of `Mystic::Configuration`

    class MyConfig < Mystic::Configuration
      def env
        # Returns String representing the env like ENV["RAILS_ENV"]
      end
      
      def env= new_env
        # setter for Mystic::Configuration#env
      end
      
      def json_column
        # the column name used when returning JSON from Postgres.
        # it should not conflict with any column names in your app (obviously)
      end
      
      def raw
      	# RETURNS Hash of Hashes (eg { "development" => { ... config here ... }
      	# this has must have symbol keys.
      end
      
      def database
    	# RETURNS Hash
        # processes the value from Mystic::Configuration#raw
        # into a hash suitable for sending to Postgres
        # as a connection options
      end
      
      def pool
        # RETURNS Hash
        # configuration hash for the connection pool
        # the connection pool is an instance of Mystic::AccessStack
      end
    end
    
    #
    # IMPORTANT IMPORTANT IMPORTANT
    #
    Mystic.config = MyConfig.new

Connecting to a Database
-

Connect to a database using the `Mystic.connect` method.

    Mystic.connect # use the current env's (Mystic.config.env) config
    Mystic.connect { :dname => "test" }, {} # connect using postgres opts & pool opts, respectively
    
You can also connect to a database by changing the environment

    Mystic.config.env = "production"

You can disconnect using

    Mystic.disconnect!
    
Not sure if you're connected?

    Mystic.connected?
    
Escaping Strings
-

**Mystic must be connected to your database**

LibPQ uses connection settings to properly encode strings and therefore, you must be connected to a database (preferrably your database). _No networking happens when a string is being escaped, despite the fact that it requires a connection._

    Mystic.escape("my_string") # escape a string
    Mystic.quote("my_literal") # escape an SQL literal. Adds single quotes
    Mystic.dblquote("my_identifier") # escape an identifier like a table name. Adds double quotes
    
NOTE: only the first two are implemented by LibPQ. The last one is implemented by this library. 

Executing SQL
-

**Mystic must be connected to your database**

    Mystic.execute "SELECT 1" # your sql
    
    
This method normally returns an array of hashes. Each hash is a row.

If you used the JSON column, it will return ONLY that column's value at row 0.

General Notes
-

Unlike other frameworks, Ruby encodes meaning in the types of objects. For example:

`Symbol`s  ->  double-quoted identifiers

`String`s  ->  single quoted literals

All other objects remain the same.


Writing a Model
-

Mystic provides a DSL for writing models. An example model looks like:

    #!/usr/bin/env ruby

    require "mystic"
    
    class Users
      include Mystic::Model
    
      table :users # define which table the model accesses
      
      column :id
      column :username
      # other columns
      
      # Mystic models have the following class methods.
      # They are called "actions"
      # 	select - return array of results
      # 	fetch - Like select, but returns one row as a hash
      # 	update - update rows
      # 	delete - delete rows
      
      # you can make custom actions:
      select_action :my_action do |params={}, opts={}|
      	# return stuff
      	# issue queries
      end
      
      # update takes 3 params
      update_action :my_update_action do |where={}, set={}, opts={}|
      
      end
    end
    
You can call custom actions like this:

    Users.select :my_action, { :param => "this" }, { :option => "value" }

Writing a Migration
-

TODO: write this

Mystic::SQL
-

`Mystic::SQL` is a wrapper around basic SQL constructs such as tables, indeces, and columns.

**`Mystic::SQL::Index`**

`:columns` must contain at least one element.

**`:name`** (optional) (`Symbol`) The name of the index. Defaults to a name generated from the columns and the table.

**`:type`** (optional) (`Symbol`) The index type. Can either be `:btree`, `:hash`, `:gist`, `:spgist`, or `:gin`.

**`:columns`** (optional) (`Array` of `Strings`, `Symbol`s, or `Column`s) the index's columns. `String`s represent SQL fragments, `Symbols` represent column names, and `Columns` are replaced with their names.

**`:fillfactor`** (optional) (`Integer`) The fillfactor storage option. Must be in the range `10..100`.

**`:tablespace`** (`Symbol`) The tablespace of the index.

**`:buffering`** (`Symbol`) The buffering storage option. Must either be `:on`, `:off`, or `:auto`.

**`:where`** (`String`) SQL fragment that determines which rows are indexed.

**`unique`** (`true`/`false`) Whether or not the table is unique.

**`:table`** (`Symbol`) The table the index is on.



Command line
-

TODO: Document Queue

Run all pending migrations

    $ mystic migrate
    
Roll back a single migration

    $ mystic rollback
    
Start a console (irb) with `Mystic` already connected to your database.
    
    $ mystic console
    
Each of these commands takes a second argument: an environment. For example:

    $ mystic {migrate, rollback, console} development

TODO
-

1. **Postgres client encodings**. As long as you don't change your DB server's encoding, you won't need to change your client encoding, and this won't affect you. The code is approximately 60% finished.
2. **Postgres notices**. Postgres issues these retarded messages when you do things like creating a table that already exists (`CREATE TABLE IF NOT EXISTS`)