Mystic
===

**Sinatra is to Rails** as **Mystic is to ActiveRecord**

Simple database connection that supplies connection pooling, server selection, raw SQL execution, and such.

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

`execute(sql_string)` => executes some raw SQL from a string.
`create_table` => Creates a table. See above

You can use the following constraints/options with your columns

>`:not_null` => true/false<br />
> Corresponds to SQL's `NOT NULL`

>`:unique` => true/false<br />
> Corresponds to SQL's `UNIQUE`

>`:primary_key` => true/false<br />
> Corresponds to SQL's `PRIMARY KEY`

>`:references` => String<br />
> Corresponds to SQL's `REFERENCES`. You must write something like this: `orders (id) ON DELETE CASCADE`

Notes
-

- Returning rows for a `DELETE` query is super expensive (in `psql`, `DELETE` queries take **10x** longer to execute with the `RETURNING` clause)



Constraints:
-







