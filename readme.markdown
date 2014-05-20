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

Migrations are subclasses of `Mystic::Migration`. They are similar to ActiveRecord, except they support any database data type using `method_missing`. Indeces are also supported using this DSL. *For example:*

    # The DB being used is Postgres
    create_table :table do |t|
      t.smallint :smallint
      t.char :guid_char, :length => 36
      t.guid :guid
      t.json :json
      
      t.index :guid_char
    end
    
You can also use the following methods in your migrations:

> `execute` => String (your SQL code)<br />
> Executes some raw SQL.

> `create_table` => Proc<br />
> Creates a table, see above.

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



Constraints:
-

TODO: Write this section

Adapters:
-

TODO: Write this section






