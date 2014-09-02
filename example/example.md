Mystic demo
==

This is an example of how you can set up a Mystic project. It includes:

1. A migration
2. Database config
3. A rack app (config.ru)

Instructions
-

1. Copy this directory elsewhere (so as to not pick up Mystic's `Gemfile`).
2. Edit `config/database.yml`. It's the same one as Rails.
3. run `$ mystic migrate`. It will default to `development` and that's cool.
4. Profit ???

Now you can run the Mystic console and screw around with Mystic in IRB.