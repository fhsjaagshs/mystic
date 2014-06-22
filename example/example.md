Mystic demo
==

This is an example of how you can set up a Mystic project. It includes a migration & a database.yml.

Instructions
-

Copy this directory elsewhere. Bundler/Rubygems will pick up Mystic's main `Gemfile` and you'll get errors about pg not being installed.

To get this working, edit the database.yml file with information about your DB (it works the same way as a Rails database.yml) and edit the migration, it was written with Postgres in mind.

Now to get this going, run

`mystic migrate <env>`

This is the same as Rails' `rake db:migrate`.

To rollback one migration, run

`mystic rollback <env>`

Now let's say you want to do some testing with running raw queries in your app, you'll want to run

`mystic console <env>`

It fires up an irb session, loads the mystic gem, and connects to the database.

Mystic also picks up your `ENV`'s `"RACK_ENV"` and falls back to `"RAILS_ENV"`.