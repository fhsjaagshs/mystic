#!/usr/bin/env ruby

require "./mystic/extensions"
require "./mystic/root"
require "./mystic/dotenv"
require "./mystic/database"
require "./mystic/sql"
require "./mystic/migration"
require "./mystic/model"

module Mystic
  JSON_COL = "mystic_return_json89788".freeze
end