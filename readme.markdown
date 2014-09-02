Mystic
===

*"Clean, easily customized Postgres access."*

**Sinatra** is to **Rails** as **Mystic** is to **ActiveRecord**

Mystic is a simple pooled database connection that supplies migrations, raw SQL execution, and such.

Why
-

I got tired of the inefficiency that high-level solutions to basic problems (like database access). I also didn't like having to learn a framework to use a language. Not cool.

And thus, Mystic was born. It solves the same problems that existing solutions do, but differently. It is based upon the following idea:

> Retrieve the exact data that is needed in a universal form.

Mystic does not force a programmer to use any kind of config**, model class, way of thinking.

** ok, sort of. You can use `config/database.yml` or you can initialize your own instance of `Mystic::Postgres` and assign it to `Mystic.postgres`

Configuration
-

First, run the following commands:

    $ cd your_project
    $ mkdir -p mystic/migrations

Now you have two options:

1. You can use `config/database.yml`.

        # connect
        Mystic.connect "production"
        Mystic.connect # will use the current RACK_ENV (falling back on RAILS_ENV, then development)
        # or
        Mystic.env = "production"
        # it's aliased, check it out in lib/mystic.rb
        
        # disconnect
        Mystic.disconnect
        
        
2. Or just pass your own `pg` parameters:

        # connect
        Mystic.manual_conn {} # pass opts like you would for the `pg` gem
        
        # disconnect
        Mystic.disconnect

Both options will set up the environment correctly.

Executing SQL
-

Once you're all configured, you can use models and execute SQL!!!

Oh shit, how do I do *that*?

    Mystic.execute "SELECT 1" # your sql
    
Great, now what does it return?

An array of `Hash`es representing rows. Every method that returns DB data does it like that.

The command line
-

You can run your migrations

    $ mystic migrate
    
You can roll them back (one at a time).

    $ mystic rollback
    
You can start a console with Mystic already configured via `config/database.yml`
    
    $ mystic console

Migrations
-

Migrations are a bit like ActiveRecord, but they allow for more low-level control. You can specify exactly which type you want for a column.

*Everything you can do with CREATE \<something\>, you can do with Mystic migrations*

you can create migrations with

    $ mystic create migration MyMigrationName
    
    
They look kinda like this (but obviously blank when first created)

    #!/usr/bin/env ruby

    require "mystic"

    class MyMigrationName < Mystic::Migration
      def up
        create_table :table do |t|
          t.guid :guid, :default => "uuid_generate_v4()", :primary_key => true, :unique => true
          t.smallint :age
          t.text :name
          t.char :data, :size => 36
          t.json :json
      
          t.index :indexname, :guid_char, :unique
        end
    
        alter_table :table do |t|
          t.rename_column :json, :json_data
          t.drop_columns :age
        end
      end
  
      def down
		drop_table :table
      end
    end

#### Migration Operations

`execute(sql)` (String) - Executes `sql`.

`create_table(name, body)` (Symbol/String, Proc) - Creates a table named `name` using `body`.

###### TODO:: Finish this


#### Column Options

###### Constraints
`:null` (`true`/`false`) - Corresponds to SQL's `NULL` and `NOT NULL`.<br />
> `:null => false`

`:unique` (`true`/`false`) - Corresponds to SQL's `UNIQUE`.<br />
> `:unique => true`

`:primary_key` (`true`/`false`) - Corresponds to SQL's `PRIMARY KEY`.<br />
> `:primary_key => true`

`:references` (String) - Corresponds to SQL's `REFERENCES`.<br />
> `:references => "orders (id) ON DELETE CASCADE"`

`:default` (String) - Corresponds to SQL's `DEFAULT`.<br />
> `:default => "uuid_generate_v4()::char(36)"`

###### Options
`:size` (Integer) - The size of a column<br />
> `:size => 255`

Models
-

Mystic models are in no way like traditional models.

* A model is any class that has `Mystic::Model` included.
* A model is never instantiated. They are classes that control access to data in the database.

Here's a basic declaration:

    class Sales
      include Mystic::Model
    end
    
You can use the `Sales` class like this:

    require "sales.rb"

    def some_meth
      # returns the created row
      Sales.create(
        :id => 1,
        :gross => 18274,
        :profit => 1000,
        :units => "dollars"
      )
      
      Sales.select(:units => "dollars") # returns matching rows
      Sales.update({:units => "dollars"}, {:units => "$"}) # updates matching rows
      Sales.delete(:units => "$") # deletes matching rows
    end

#### The `opts` hash

The preceding example omits an optional hash at the end: The `opts` hash. This hash can be used to further define what gets returned.

> `:return_rows` - true/false<br />
> Determines if a non-`SELECT` query returns rows. Default `true` for `SELECT` and `UPDATE`. The default for `DELETE` queries is `false` ***

> `:return_json` - true/false<br />
> Determines if a query returns rows as JSON.

> `:count` - Integer<br />
> The number of rows to return. Only available on SELECT queries.

> `:plural` - true/false<br />
> Whether or not to return a result wrapped in an array. It will return the first returned row.


*** Returning rows from `DELETE` queries takes a really long time.

Writing Custom models
-

This is something you probably will be doing. It's life. Sometimes data doesn't fit precicely into rows, or sometimes it's not even in Postgres (Maybe it's in MongoDB? Remember to use `AccessStack`).

####Model configuration methods

You should override these.

`Mystic::Model.table_name` - none<br />
Returns the name of the table. By default it's the name of the model downcased.<br />

`Mystic::Model.visible_cols` - none<br />
Returns an array of strings representing columns to be returned from SQL queries.<br />

####SQL generation methods

`self.op_sql` - Generates SQL for operation `op`.<br />
It takes the same parameters as `self.op` (`self.create`).<br />

`self.fetch where={}, opts={}` - SELECTs one entry matching `where`<br />

`self.select where={}, opts={}` - SELECTs rows from the database matching `where`<br />

`self.create entry={}, opts={}` - INSERTs `entry` as a row<br />

`self.update where={}, set={}, opts={}` - UPDATEs rows matching `where` with `set`<br />

`self.delete where={}, opts={}` - DELETE rows matching `where`<br />

`self.function_sql` - Symbol and Array of arguments<br />
Generates SQL to execute a function/procedure
`Model.function_sql :do_something, "param_one", "param_two", "param_three"`<br />

TODO
-

1. A method wrapping `quote_ident()`
2. Rollback multiple migrations
3. Rollback to a migration by name or number (or both)
4. Project generator



