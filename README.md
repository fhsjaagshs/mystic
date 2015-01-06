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
      
      def database
        # RETURNS Hash of Hashes (eg { "development" => { ... config here ... }
        # defaults to loaded config from config/database.yml
      end
      
      def postgres
        # RETURNS Hash
        # connection hashmap for Mystic::Postgres.new
      end
      
      def pool
        # RETURNS Hash
        # configuration hash for the connection pool
        # the connection pool is an instance of AccessStack***
      end
    end
    
    #
    # IMPORTANT IMPORTANT IMPORTANT
    #
    Mystic.config = MyConfig.new
    
*** See github.com/fhsjaagshs/access_stack

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

Writing a Model
-

TODO: write this

Writing a Migration
-

TODO: write this

Command line
-

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