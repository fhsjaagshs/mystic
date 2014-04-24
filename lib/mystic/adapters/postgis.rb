#!/usr/bin/env ruby

require "mystic"
require "mystic/adapters/postgres"

class PostgisAdapter < PostgresAdapter
  def geospatial_sql_type(col)
    "(#{col.geom_kind}, #{col.geom_srid})"
  end
end