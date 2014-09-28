#!/usr/bin/env ruby

require_relative "./mystic/extensions"
require_relative "./mystic/root"
require_relative "./mystic/dotenv"
require_relative "./mystic/database"
require_relative "./mystic/sql"
require_relative "./mystic/migration"
require_relative "./mystic/model"

module Mystic
  JSON_COL = "mystic_return_json89788".freeze
end