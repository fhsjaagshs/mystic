Mystic
===

*"Ultra-dynamic replacement for ActiveRecord that allows for fine-grain control over database queries."*

**Sinatra** is to **Rails** as **Mystic** is to **ActiveRecord**

Simple database connection that supplies connection pooling, migrations, raw SQL execution, and such.

- Allows the developer to write their own SQL
- Supports models
- Supports `ActiveRecord`-esque migrations
- Allows the developer to write their own adapters

Migrations
-

Migrations are `Mystic::Migration` subclasses. Unlike ActiveRecord, you can dynamically specify any datatype and you're in complete control of a column's properties. `Mystic::Migration` also supports indeces. Here's an example of a migration:

    # The DB being used is Postgres
    create_table :table do |t|
      t.smallint :smallint
      t.char :guid_char, :size => 36, :unique => true
      t.guid :guid, :default => "uuid_generate_v4()"
      t.json :json
      
      t.index :guid_char
    end
    
#### Migration operations

> `execute` => String (your SQL code)<br />
> Executes some raw SQL.

> `create_table` => Proc<br />
> Creates a table, see above.

###### TODO: Finish this part

#### Column Options

###### Constraints
> `:null` true/false<br />
> Corresponds to SQL's `NULL` and `NOT NULL`.
> > `:null => false`

> `:unique` true/false<br />
> Corresponds to SQL's `UNIQUE`.<br />
> > `:unique => true`

> `:primary_key` true/false<br />
> Corresponds to SQL's `PRIMARY KEY`.<br />
> > `:primary_key => true`

> `:references` String<br />
> Corresponds to SQL's `REFERENCES`.<br />
> > `:references => "orders (id) ON DELETE CASCADE"`

> `:default` String<br />
> Corresponds to SQL's `DEFAULT`.<br />
> > `:default => "uuid_generate_v4()::char(36)"`

###### Options
> `:size` Integer<br />
> The size of a column<br />
> > `:size => 255`

Models:
-

Ultimately, models are just `Object`s that have methods for basic CRUD database operations.

Models provide the following methods:

####Model configuration methods

> `self.table_name` - none<br />
> Returns the name of the table. By default it's the name of the model downcased.

> `self.visible_cols` - none<br />
> Returns an array of strings representing columns to be returned from SQL queries

####SQL generation methods

Each of these take two hashes as params. They are defined as

`def self.*(params={},opts={})`

`params` is a hash with column name as a key and the value as a value.

> `self.*_sql` - See model.rb<br />
> Generates SQL for an SQL operation based upon a hash of fields and values

> `self.fetch` - SELECTs one entry matching criteria

> `self.select` - SELECTs rows from the database
> `self.insert` - INSERT a row
> `self.delete` - DELETE rows from the database

These, well, don't:

> `self.function_sql` - Symbol and Array of arguments<br />
> Generates SQL to execute a function/procedure<br />
> `Model.function_sql(:do_something, "param_one", "param_two", "param_three")`

> `self.udpate` - UPDATE rows
> It's defined as `self.update_sql(where={}, set={}, opts={})`


####Model options

> `:return_rows` - true/false<br />
> Determines if a non-`SELECT` query returns rows.

> `:return_json` - true/false<br />
> Determines if a query returns rows as JSON. **Postgres only**. 

> `:count` - Integer<br />
> The number of rows to return. Only available on SELECT queries.

Notes:
-

- Returning rows for a `DELETE` query is super expensive (in `psql`, `DELETE` queries take **10x** longer to execute with the `RETURNING` clause)
- Returning JSON from the DB is only supported by Postgres.

Adapters:
-

Unlike ActiveRecord, Mystic adapters are really simple. They're defined using a simple DSL that resembles Sinatra or NYNY:

    require "mystic"
    
    module Mystic
      class MysqlAdapter < Mystic::Adapter
        execute do |inst, sql|
	      # Execute SQL and turn it into Ruby objects  
	      # inst - An instance of the database gem
	      # sql - The SQL to execute
	    end
  
       sanitize do |inst, str|
		 # Sanitize a string
		 # inst - An instance of the database gem
	     # str - The string to sanitize
	   end
  
	    connect do |opts|
	      # Create an instance of your database gem
	      # opts - the options from database.yml that you shall feed to the DB gem
 	    end
  
	    disconnect do |inst|
	      # close the database gem's connection
	    end
	  
        sql do |obj|
          # Turn a Mystic::SQL object into SQL
          # obj - The Mystic::SQL object
        end
      end
    end
    
    






