#!/usr/bin/env ruby

require "mystic/adapters/postgres"
require "pg"

module Mystic
  class Table
    def geometry(name, kind, srid, opts={})
      opts[:geom_kind] = kind.to_s
      opts[:geom_srid] = srid.to_s
      column(:geometry, name, opts)
    end
  end
end

class PostgisAdapter < PostgresAdapter
  # this is essentially a name change for 
  # the PostgresAdapter class
  # It allows the column_sql(type,name,opts) method to 
end