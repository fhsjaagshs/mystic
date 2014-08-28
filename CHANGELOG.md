v 0.0.1

- Initial release

v 0.0.2

- Make load_env() method public

v 0.0.3

- Fixed mystic console

v 0.0.4

- Add `CASCADE`/`RESTRICT` parameter for dropping tables

v 0.0.5

- Fixed issue with calling empty?() on a random param
- Made Pathname's to_s() method faster by making it directly return @path

v.0.0.6

- Fixed issue with JSON generation and selecting one row

v 0.0.7

- Fixed double row_to_json() for insert queries

v 0.0.8

- Fixed env loading bug on Heroku

v 0.0.9

- Fixed a bug where Heroku-generated database.yml's would not work DUE TO ASSUMPTIONS ON HEROKU'S PART.

v 0.1.0

- Complete rewrite
    * Postgres-only
    * `Mystic::Model` is now a mixin
    * Removed unnecessary syntactic sugar
    
v 0.1.1

- Fixed a bug with rescue in `Mystic::load_env`

v 0.1.2

- Improved database.yml configuration