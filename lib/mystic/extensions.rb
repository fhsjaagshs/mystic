#!/usr/bin/env ruby

class String
  def sqlize
    self.capitalize.split("_").join(" ")
  end
end

class Symbol
  def sqlize
    self.to_s.sqlize
  end
end