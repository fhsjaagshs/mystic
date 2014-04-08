#!/usr/bin/env ruby

require "mystic"
require "mystic/adapters/postgres"
require "pg"

class PostgisAdapter < PostgresAdapter
  # this is essentially a name change for 
  # the PostgresAdapter class
  # It allows the column_sql(type,name,opts) method to 
  
  def geospatial_sql_type(col)
    "(#{col.geom_kind}, #{col.geom_srid})"
  end
end