#!/usr/bin/env ruby

module Mystic
  module SQL
		class Raw < SQLObject
			def initialize opts
				@sql = opts[:sql]
			end
			
			def to_sql
				@sql
			end
		end
  end
end