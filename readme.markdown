Mystic
===

*"Ultra-dynamic replacement for ActiveRecord that allows for fine-grain control over database queries."*

**Sinatra** is to **Rails** as **Mystic** is to **ActiveRecord**

Simple database connection that supplies connection pooling, migrations, raw SQL execution, and such.

- Allows the developer to write their own SQL
- Supports 'models'
- Supports `ActiveRecord`-style migrations
- Allows the developer to write their own adapters

Philosophy
-

Mystic aims to provide **generic SQL generation where it's appropriate** (migrations, basic CRUD), but **back off when there is work to do** (complex queries, etc).

Mystic embraces Ruby's dynamicity, but only in Ruby. Once queries are required, they're raw SQL written by the programmer (except in the cases of basic CRUD).

Get out there and DIY.

Migrations
-

Migrations are `Mystic::Migration` subclasses. Unlike ActiveRecord, you can dynamically specify any datatype and you're in complete control of a column's *every* property. `Mystic::Migration` also supports indeces. Here's an example of a migration:

    # The DB being used is Postgres
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


TODO
-

1. `quote_ident()` implementation




