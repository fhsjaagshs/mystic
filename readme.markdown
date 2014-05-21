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

Migrations are `Mystic::Migration` subclasses. Unlike ActiveRecord, you can dynamically specify any datatype and you're in complete control of a columns properties. `Mystic::Migration` also supports indeces. Here's an example of a migration:

    # The DB being used is Postgres
    create_table :table do |t|
      t.smallint :smallint
      t.char :guid_char, :length => 36
      t.guid :guid
      t.json :json
      
      t.index :guid_char
    end
    
You can use the following methods in your migrations:

> `execute` => String (your SQL code)<br />
> Executes some raw SQL.

> `create_table` => Proc<br />
> Creates a table, see above.

###### TODO: Finish this part

You can use the following constraints/options with your columns

> `:null` => true/false<br />
> Corresponds to SQL's `NULL` and `NOT NULL`.

> `:unique` => true/false<br />
> Corresponds to SQL's `UNIQUE`.

> `:primary_key` => true/false<br />
> Corresponds to SQL's `PRIMARY KEY`.

> `:references` => String<br />
> Corresponds to SQL's `REFERENCES`.<br />
> `:references => "orders (id) ON DELETE CASCADE"`

> `:default` => String<br />
> Corresponds to SQL's `DEFAULT`.<br />
> `:default => "uuid_generate_v4()::char(36)"`


Notes
-

- Returning rows for a `DELETE` query is super expensive (in `psql`, `DELETE` queries take **10x** longer to execute with the `RETURNING` clause)
- Returning JSON from the DB is only supported by Postgres.

Constraints:
-

TODO: Write this section

Adapters:
-

There is a simple DSL for writing adapters.

TODO: Write this section






