Mystic
===

**Sinatra:Rails** as **Mystic:ActiveRecord**

Migrations

Columns:
- The variously named methods of Mystic::SQL::Table
- add_column


*Constraints:*

Constraints are passed in the same way as options like `:size`

>`:not_null` => true/false<br />
> Corresponds to SQL's `NOT NULL`

>`:unique` => true/false<br />
> Corresponds to SQL's `UNIQUE`

>`:primary_key` => true/false<br />
> Corresponds to SQL's `PRIMARY KEY`

>`:references` => String<br />
> Corresponds to SQL's `REFERENCES`. You must write something like this: `orders (id) ON DELETE CASCADE`





