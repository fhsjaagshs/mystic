#!/usr/bin/env ruby

require "./mystic/constants"
require "./mystic/extensions"
require "./mystic/dotenv"
require "./mystic/root"
require "./mystic/sql"
require "./mystic/migration"
require "./mystic/model"
require "./mystic/database"

module Mystic
  JSON_COL = "mystic_return_json89788".freeze
end